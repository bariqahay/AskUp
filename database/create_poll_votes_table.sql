-- Create poll_votes table to track student votes
CREATE TABLE IF NOT EXISTS poll_votes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    poll_id UUID NOT NULL REFERENCES polls(id) ON DELETE CASCADE,
    option_id UUID NOT NULL REFERENCES poll_options(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Each student can only vote once per poll
    CONSTRAINT unique_poll_vote UNIQUE (poll_id, student_id)
);

-- Create indexes for better query performance
CREATE INDEX idx_poll_votes_poll_id ON poll_votes(poll_id);
CREATE INDEX idx_poll_votes_student_id ON poll_votes(student_id);
CREATE INDEX idx_poll_votes_option_id ON poll_votes(option_id);

-- Add Row Level Security (RLS)
ALTER TABLE poll_votes ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view all votes (for counting purposes)
CREATE POLICY "Anyone can view poll votes"
    ON poll_votes FOR SELECT
    USING (true);

-- Policy: Users can insert their own votes
CREATE POLICY "Users can insert their own votes"
    ON poll_votes FOR INSERT
    WITH CHECK (auth.uid() = student_id);

-- Policy: Users can delete their own votes (to allow changing vote)
CREATE POLICY "Users can delete their own votes"
    ON poll_votes FOR DELETE
    USING (auth.uid() = student_id);

-- Note: After creating this table in Supabase, update the _loadDashboardData() 
-- function in student_dashboard_screen.dart to uncomment the poll_votes query
