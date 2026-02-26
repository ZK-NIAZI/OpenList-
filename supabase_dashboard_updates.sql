-- ============================================
-- Dashboard Feature Updates
-- ============================================

-- Add pinned field to notes
ALTER TABLE public.notes 
ADD COLUMN IF NOT EXISTS is_pinned BOOLEAN DEFAULT FALSE;

-- Add status and scheduled_time to tasks
ALTER TABLE public.tasks 
ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'active',
ADD COLUMN IF NOT EXISTS scheduled_time TIME;

-- Add color field to tasks for custom color coding
ALTER TABLE public.tasks 
ADD COLUMN IF NOT EXISTS color TEXT;

-- Create index for pinned notes
CREATE INDEX IF NOT EXISTS idx_notes_pinned ON public.notes(is_pinned, owner_id);

-- Create index for today's tasks
CREATE INDEX IF NOT EXISTS idx_tasks_due_date ON public.tasks(due_date, owner_id);

-- Create index for task status
CREATE INDEX IF NOT EXISTS idx_tasks_status ON public.tasks(status, owner_id);

-- Function to automatically set task status based on due date
CREATE OR REPLACE FUNCTION public.update_task_status()
RETURNS TRIGGER AS $$
BEGIN
  -- If task is completed, status is 'completed'
  IF NEW.is_completed = TRUE THEN
    NEW.status = 'completed';
  -- If due date is in the past and not completed, status is 'overdue'
  ELSIF NEW.due_date IS NOT NULL AND NEW.due_date < NOW() AND NEW.is_completed = FALSE THEN
    NEW.status = 'overdue';
  -- Otherwise, status is 'active'
  ELSE
    NEW.status = 'active';
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update task status automatically
DROP TRIGGER IF EXISTS set_task_status ON public.tasks;
CREATE TRIGGER set_task_status
  BEFORE INSERT OR UPDATE ON public.tasks
  FOR EACH ROW EXECUTE FUNCTION public.update_task_status();

-- View for dashboard statistics
CREATE OR REPLACE VIEW public.dashboard_stats AS
SELECT 
  owner_id,
  COUNT(*) FILTER (WHERE status = 'active') as active_count,
  COUNT(*) FILTER (WHERE status = 'completed') as completed_count,
  COUNT(*) FILTER (WHERE status = 'overdue') as overdue_count,
  COUNT(*) as total_count,
  ROUND(COUNT(*) FILTER (WHERE status = 'completed')::numeric / NULLIF(COUNT(*), 0) * 100, 0) as completion_percentage
FROM public.tasks
GROUP BY owner_id;

-- Grant access to the view
GRANT SELECT ON public.dashboard_stats TO authenticated;
