SELECT id,
       "messageType",
       "key"::text AS key_json,
       COALESCE("contextInfo"::text, 'null') AS context_json,
       left("message"::text, 1500) AS message_json,
       "messageTimestamp",
       source,
       status,
       "instanceId"
FROM evolution_api."Message"
WHERE "messageTimestamp" BETWEEN 1776365660 AND 1776365735
ORDER BY "messageTimestamp" DESC, id DESC
LIMIT 20;
