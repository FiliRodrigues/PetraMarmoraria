CREATE OR REPLACE FUNCTION public.get_reports_summary(p_month INT, p_year INT)
RETURNS TABLE(
  total_created INT,
  total_delivered INT,
  total_quoted DECIMAL,
  on_time INT,
  overdue INT,
  in_progress INT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    COUNT(*) FILTER (WHERE EXTRACT(MONTH FROM created_at) = p_month AND EXTRACT(YEAR FROM created_at) = p_year)::INT,
    COUNT(*) FILTER (WHERE status = 'entrega' AND EXTRACT(MONTH FROM updated_at) = p_month AND EXTRACT(YEAR FROM updated_at) = p_year)::INT,
    COALESCE(SUM(total_value) FILTER (WHERE EXTRACT(MONTH FROM created_at) = p_month AND EXTRACT(YEAR FROM created_at) = p_year), 0),
    COUNT(*) FILTER (WHERE status = 'entrega' AND scheduled_date IS NOT NULL AND scheduled_date >= updated_at::date)::INT,
    COUNT(*) FILTER (WHERE status != 'entrega' AND scheduled_date IS NOT NULL AND scheduled_date < CURRENT_DATE)::INT,
    COUNT(*) FILTER (WHERE status != 'entrega')::INT
  FROM public.service_orders;
END;
$$ LANGUAGE plpgsql STABLE;
