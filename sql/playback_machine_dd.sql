CREATE TABLE av_files (
	title		text primary key
);



CREATE TABLE av_file_component (
	file		text NOT NULL,
	title		text REFERENCES av_files 
						ON DELETE CASCADE
						ON UPDATE CASCADE,
	duration	interval NOT NULL,
	sequence_no	int DEFAULT (0),
	PRIMARY KEY (file,sequence_no)
);

CREATE TABLE fill_shorts (
	title		text REFERENCES av_files ON DELETE CASCADE
						 ON UPDATE CASCADE,
	group_name 	text
);

CREATE TABLE contents (
	title		text PRIMARY KEY REFERENCES av_files
				ON DELETE CASCADE
				ON UPDATE CASCADE,
	type		text,
	director	text,
	description	text
);

CREATE TABLE schedules (
	name		text primary key
);

CREATE TABLE content_schedule (
	id		SERIAL PRIMARY KEY,
	title 		text not null references av_files
				ON DELETE CASCADE
				ON UPDATE CASCADE,
	schedule	text DEFAULT 'Baycon 2005' references schedules (name) 
				ON DELETE CASCADE
				ON UPDATE CASCADE,
	listed		boolean DEFAULT true,
	start_time	timestamp WITH TIME ZONE NOT NULL,
	UNIQUE(start_time,schedule)
);

CREATE FUNCTION avfile_duration(text) RETURNS interval AS '
DECLARE
total_length INTERVAL;
stitle ALIAS FOR $1;
BEGIN
	select sum(duration) into total_length from av_file_component 
		where title = stitle;
	RETURN total_length;
END
' LANGUAGE 'plpgsql';

CREATE FUNCTION stop_time(text,timestamp with time zone) 
RETURNS timestamp with time zone AS '
DECLARE
stitle ALIAS FOR $1;
start_time ALIAS FOR $2;
BEGIN
	RETURN start_time + avfile_duration(stitle);
END
' LANGUAGE 'plpgsql';


CREATE FUNCTION check_overlap() RETURNS TRIGGER AS '
BEGIN
	IF EXISTS( SELECT id FROM content_schedule
		WHERE schedule = NEW.schedule
			AND id != NEW.id
			AND overlaps(NEW.start_time, ( avfile_duration(NEW.title) + INTERVAL ''1 sec''), start_time, ( avfile_duration(title) + INTERVAL ''1 sec''))
	)
	THEN
		RAISE EXCEPTION ''Schedule entry conflicts with existing entry'';
	END IF;
	RETURN NEW;
END;
' LANGUAGE 'plpgsql';

CREATE TRIGGER content_check_overlap BEFORE INSERT OR UPDATE ON content_schedule
	FOR EACH ROW EXECUTE PROCEDURE check_overlap();


---
--- Views
---
CREATE OR REPLACE VIEW fills AS
	SELECT title, avfile_duration(title) AS duration
	FROM fill_shorts;


--
-- Listing of movie contents
CREATE OR REPLACE VIEW movies AS
	SELECT title, avfile_duration(title) AS duration
	FROM contents;


CREATE OR REPLACE VIEW schedule_times AS
	SELECT 
		content_schedule.id as id,
		content_schedule.title,
		schedule,
		start_time,
		stop_time(content_schedule.title,start_time) AS stop_time,
		description,
		listed
	FROM content_schedule,contents
	WHERE contents.title = content_schedule.title;
	

CREATE OR REPLACE VIEW schedule_times_raw AS
	SELECT 
		id,
	 	title,
		schedule,
		description,
               	date_part('epoch', start_time) AS start_time,
               	date_part('epoch', stop_time) AS stop_time,
		listed
	FROM schedule_times;


---
--- Permissions
---
GRANT SELECT ON TABLE schedules TO apache;
GRANT SELECT ON TABLE av_file_component TO apache;
GRANT SELECT ON TABLE schedule_times TO apache;
GRANT SELECT ON TABLE movies TO apache;
GRANT SELECT ON TABLE fills TO apache;
GRANT ALL ON TABLE content_schedule TO apache;
GRANT ALL ON TABLE av_files TO apache;
GRANT ALL ON TABLE content_schedule_id_seq TO apache;
