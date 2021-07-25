-- Display the name of the column and what type of data is stored in that column
SELECT COLUMN_NAME, DATA_TYPE
-- Set which database we are looking at; the rest is common to all SQL Databases
FROM ProjectsDatabase.INFORMATION_SCHEMA.COLUMNS
-- Selecting down to just the Table we are interested in; could be multiple
WHERE TABLE_NAME = 'CovidMaster'
-- Ordering by how it appears in the Table
ORDER BY ORDINAL_POSITION