-- OpenList Supabase Schema
-- Run this in your Supabase SQL Editor

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Items table (tasks, notes, lists, sections)
CREATE TABLE IF NOT EXISTS items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  space_id UUID,
  parent_id UUID REFERENCES items(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('task', 'note', 'list', 'section')),
  title TEXT NOT NULL,
  content TEXT,
  is_pinned BOOLEAN DEFAULT FALSE,
  is_completed BOOLEAN DEFAULT FALSE,
  due_date TIMESTAMPTZ,
  reminder_at TIMESTAMPTZ,
  created_by UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  order_index INTEGER DEFAULT 0,
  category TEXT,
  CONSTRAINT items_created_by_fkey FOREIGN KEY (created_by) REFERENCES auth.users(id) ON DELETE CASCADE
);

-- Blocks table (atomic content blocks for items)
CREATE TABLE IF NOT EXISTS blocks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  item_id UUID NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('text', 'heading', 'checklist', 'bullet', 'image', 'code')),
  content TEXT NOT NULL,
  is_checked BOOLEAN DEFAULT FALSE,
  order_index INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT blocks_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE CASCADE
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_items_space_id ON items(space_id);
CREATE INDEX IF NOT EXISTS idx_items_parent_id ON items(parent_id);
CREATE INDEX IF NOT EXISTS idx_items_created_by ON items(created_by);
CREATE INDEX IF NOT EXISTS idx_items_type ON items(type);
CREATE INDEX IF NOT EXISTS idx_items_is_pinned ON items(is_pinned);
CREATE INDEX IF NOT EXISTS idx_items_due_date ON items(due_date);
CREATE INDEX IF NOT EXISTS idx_blocks_item_id ON blocks(item_id);

-- Row Level Security (RLS)
ALTER TABLE items ENABLE ROW LEVEL SECURITY;
ALTER TABLE blocks ENABLE ROW LEVEL SECURITY;

-- RLS Policies for items
CREATE POLICY "Users can view their own items"
  ON items FOR SELECT
  USING (auth.uid() = created_by);

CREATE POLICY "Users can insert their own items"
  ON items FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update their own items"
  ON items FOR UPDATE
  USING (auth.uid() = created_by);

CREATE POLICY "Users can delete their own items"
  ON items FOR DELETE
  USING (auth.uid() = created_by);

-- RLS Policies for blocks
CREATE POLICY "Users can view blocks of their items"
  ON blocks FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM items
      WHERE items.id = blocks.item_id
      AND items.created_by = auth.uid()
    )
  );

CREATE POLICY "Users can insert blocks for their items"
  ON blocks FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM items
      WHERE items.id = blocks.item_id
      AND items.created_by = auth.uid()
    )
  );

CREATE POLICY "Users can update blocks of their items"
  ON blocks FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM items
      WHERE items.id = blocks.item_id
      AND items.created_by = auth.uid()
    )
  );

CREATE POLICY "Users can delete blocks of their items"
  ON blocks FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM items
      WHERE items.id = blocks.item_id
      AND items.created_by = auth.uid()
    )
  );

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for updated_at
CREATE TRIGGER update_items_updated_at
  BEFORE UPDATE ON items
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_blocks_updated_at
  BEFORE UPDATE ON blocks
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
