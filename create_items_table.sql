-- Create Items Table for OpenList
-- This table combines tasks, notes, lists, and sections into one unified structure

-- Enable UUID extension (if not already enabled)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Drop existing items table if it exists (to start fresh)
DROP TABLE IF EXISTS items CASCADE;
DROP TABLE IF EXISTS blocks CASCADE;

-- Items table (tasks, notes, lists, sections)
CREATE TABLE items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  space_id UUID,
  parent_id UUID,
  type TEXT NOT NULL CHECK (type IN ('task', 'note', 'list', 'section')),
  title TEXT NOT NULL,
  content TEXT,
  is_pinned BOOLEAN DEFAULT FALSE,
  is_completed BOOLEAN DEFAULT FALSE,
  due_date TIMESTAMPTZ,
  reminder_at TIMESTAMPTZ,
  created_by UUID NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  order_index INTEGER DEFAULT 0,
  category TEXT
);

-- Add foreign key constraints after table creation
ALTER TABLE items
  ADD CONSTRAINT items_parent_id_fkey 
  FOREIGN KEY (parent_id) 
  REFERENCES items(id) 
  ON DELETE CASCADE;

ALTER TABLE items
  ADD CONSTRAINT items_created_by_fkey 
  FOREIGN KEY (created_by) 
  REFERENCES auth.users(id) 
  ON DELETE CASCADE;

-- Blocks table (atomic content blocks for items)
CREATE TABLE blocks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  item_id UUID NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('text', 'heading', 'checklist', 'bullet', 'image', 'code')),
  content TEXT NOT NULL,
  is_checked BOOLEAN DEFAULT FALSE,
  order_index INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add foreign key for blocks
ALTER TABLE blocks
  ADD CONSTRAINT blocks_item_id_fkey 
  FOREIGN KEY (item_id) 
  REFERENCES items(id) 
  ON DELETE CASCADE;

-- Indexes for performance
CREATE INDEX idx_items_space_id ON items(space_id);
CREATE INDEX idx_items_parent_id ON items(parent_id);
CREATE INDEX idx_items_created_by ON items(created_by);
CREATE INDEX idx_items_type ON items(type);
CREATE INDEX idx_items_is_pinned ON items(is_pinned);
CREATE INDEX idx_items_due_date ON items(due_date);
CREATE INDEX idx_blocks_item_id ON blocks(item_id);

-- Enable Row Level Security (RLS)
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

-- Success message
DO $$
BEGIN
  RAISE NOTICE '✅ Items and Blocks tables created successfully!';
  RAISE NOTICE '✅ RLS policies enabled';
  RAISE NOTICE '✅ Indexes created';
  RAISE NOTICE '✅ Ready to sync with Flutter app';
END $$;
