-- RPC Function: get_lecturer_stats
-- Returns statistics for a lecturer: sessions_created, sessions_reached, and avg_rating

CREATE OR REPLACE FUNCTION get_lecturer_stats(p_lecturer_id UUID)
RETURNS TABLE (
  sessions_created INT,
  sessions_reached INT,
  avg_rating NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COUNT(DISTINCT s.id)::INT AS sessions_created,
    COALESCE(SUM(DISTINCT sp.student_count), 0)::INT AS sessions_reached,
    COALESCE(AVG(sr.rating), 0)::NUMERIC AS avg_rating
  FROM sessions s
  LEFT JOIN (
    SELECT session_id, COUNT(DISTINCT student_id) AS student_count
    FROM session_participants
    GROUP BY session_id
  ) sp ON s.id = sp.session_id
  LEFT JOIN session_ratings sr ON s.id = sr.session_id
  WHERE s.lecturer_id = p_lecturer_id;
END;
$$ LANGUAGE plpgsql;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_lecturer_stats(UUID) TO authenticated;
