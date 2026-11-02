-- Paso 1: fechas posteriores al corte del dataset (2013-12-31) pasan a NULL.
UPDATE clean.objects SET
    founded_at         = CASE WHEN founded_at         > DATE '2013-12-31' THEN NULL ELSE founded_at END,
    closed_at          = CASE WHEN closed_at          > DATE '2013-12-31' THEN NULL ELSE closed_at END,
    first_milestone_at = CASE WHEN first_milestone_at > DATE '2013-12-31' THEN NULL ELSE first_milestone_at END,
    last_milestone_at  = CASE WHEN last_milestone_at  > DATE '2013-12-31' THEN NULL ELSE last_milestone_at END;

UPDATE clean.funds SET funded_at = NULL WHERE funded_at > DATE '2013-12-31';

-- Paso 2: si la empresa tiene un evento anterior a su fundación, se descarta founded_at.
UPDATE clean.objects SET founded_at = NULL
WHERE founded_at IS NOT NULL
  AND id IN (
      SELECT r.object_id FROM clean.funding_rounds r
        JOIN clean.objects o ON o.id = r.object_id
        WHERE r.funded_at < o.founded_at
      UNION
      SELECT a.acquired_object_id FROM clean.acquisitions a
        JOIN clean.objects o ON o.id = a.acquired_object_id
        WHERE a.acquired_at < o.founded_at
      UNION
      SELECT i.object_id FROM clean.ipos i
        JOIN clean.objects o ON o.id = i.object_id
        WHERE i.public_at < o.founded_at
  );