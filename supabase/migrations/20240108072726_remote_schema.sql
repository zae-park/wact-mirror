
SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '"public", "extensions"', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

CREATE EXTENSION IF NOT EXISTS "pgsodium" WITH SCHEMA "pgsodium";

CREATE EXTENSION IF NOT EXISTS "http" WITH SCHEMA "extensions";

CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";

CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";

CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";

CREATE EXTENSION IF NOT EXISTS "pgjwt" WITH SCHEMA "extensions";

CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";

CREATE OR REPLACE FUNCTION "public"."delete_avatar"(avatar_url text, OUT status integer, OUT content text) RETURNS record
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
begin
  select
      into status, content
           result.status, result.content
      from public.delete_storage_object('avatars', avatar_url) as result;
end;
$$;

ALTER FUNCTION "public"."delete_avatar"(avatar_url text, OUT status integer, OUT content text) OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."delete_old_avatar"() RETURNS trigger
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
declare
  status int;
  content text;
  avatar_name text;
begin
  if coalesce(old.avatar_url, '') <> ''
      and (tg_op = 'DELETE' or (old.avatar_url <> coalesce(new.avatar_url, ''))) then
    -- extract avatar name
    avatar_name := old.avatar_url;
    select
      into status, content
      result.status, result.content
      from public.delete_avatar(avatar_name) as result;
    if status <> 200 then
      raise warning 'Could not delete avatar: % %', status, content;
    end if;
  end if;
  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$$;

ALTER FUNCTION "public"."delete_old_avatar"() OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."delete_old_profile"() RETURNS trigger
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
begin
  delete from public.profiles where id = old.id;
  return old;
end;
$$;

ALTER FUNCTION "public"."delete_old_profile"() OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."delete_storage_object"(bucket text, object text, OUT status integer, OUT content text) RETURNS record
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
declare
  project_url text := '<YOURPROJECTURL>';
  service_role_key text := '<YOURSERVICEROLEKEY>'; --  full access needed
  url text := project_url||'/storage/v1/object/'||bucket||'/'||object;
begin
  select
      into status, content
           result.status::int, result.content::text
      FROM extensions.http((
    'DELETE',
    url,
    ARRAY[extensions.http_header('authorization','Bearer '||service_role_key)],
    NULL,
    NULL)::extensions.http_request) as result;
end;
$$;

ALTER FUNCTION "public"."delete_storage_object"(bucket text, object text, OUT status integer, OUT content text) OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."handle_new_user"() RETURNS trigger
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
begin
  insert into public.profiles (id, full_name, avatar_url)
  values (new.id, new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'avatar_url');
  return new;
end;
$$;

ALTER FUNCTION "public"."handle_new_user"() OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";

CREATE TABLE IF NOT EXISTS "public"."posts" (
    "id" integer NOT NULL,
    "author_id" uuid NOT NULL,
    "author" text,
    "title" text,
    "content" text,
    "image_urls" text[],
    "comments" jsonb,
    "created_at" timestamp with time zone DEFAULT now(),
    "updated_at" timestamp with time zone DEFAULT now()
);

ALTER TABLE "public"."posts" OWNER TO "postgres";

CREATE SEQUENCE IF NOT EXISTS "public"."posts_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE "public"."posts_id_seq" OWNER TO "postgres";

ALTER SEQUENCE "public"."posts_id_seq" OWNED BY "public"."posts"."id";

CREATE TABLE IF NOT EXISTS "public"."profiles" (
    "id" uuid NOT NULL,
    "updated_at" timestamp with time zone,
    "username" text,
    "full_name" text,
    "avatar_url" text,
    "university" text,
    CONSTRAINT "username_length" CHECK ((char_length(username) >= 3))
);

ALTER TABLE "public"."profiles" OWNER TO "postgres";

ALTER TABLE ONLY "public"."posts" ALTER COLUMN "id" SET DEFAULT nextval('posts_id_seq'::regclass);

ALTER TABLE ONLY "public"."posts"
    ADD CONSTRAINT "posts_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_username_key" UNIQUE ("username");

ALTER TABLE ONLY "public"."posts"
    ADD CONSTRAINT "posts_author_id_fkey" FOREIGN KEY (author_id) REFERENCES auth.users(id);

ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_id_fkey" FOREIGN KEY (id) REFERENCES auth.users(id);

CREATE POLICY "Public profiles are viewable by everyone." ON "public"."profiles" FOR SELECT USING (true);

CREATE POLICY "Users can insert their own profile." ON "public"."profiles" FOR INSERT WITH CHECK ((auth.uid() = id));

CREATE POLICY "Users can update own profile." ON "public"."profiles" FOR UPDATE USING ((auth.uid() = id));

CREATE POLICY "delete_policy" ON "public"."posts" FOR DELETE USING ((auth.uid() = author_id));

CREATE POLICY "insert_policy" ON "public"."posts" FOR INSERT WITH CHECK ((auth.uid() = author_id));

ALTER TABLE "public"."posts" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."profiles" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "select_policy" ON "public"."posts" FOR SELECT USING (true);

CREATE POLICY "update_policy" ON "public"."posts" FOR UPDATE USING ((auth.uid() = author_id));

GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";

GRANT ALL ON FUNCTION "public"."delete_avatar"(avatar_url text, OUT status integer, OUT content text) TO "anon";
GRANT ALL ON FUNCTION "public"."delete_avatar"(avatar_url text, OUT status integer, OUT content text) TO "authenticated";
GRANT ALL ON FUNCTION "public"."delete_avatar"(avatar_url text, OUT status integer, OUT content text) TO "service_role";

GRANT ALL ON FUNCTION "public"."delete_old_avatar"() TO "anon";
GRANT ALL ON FUNCTION "public"."delete_old_avatar"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."delete_old_avatar"() TO "service_role";

GRANT ALL ON FUNCTION "public"."delete_old_profile"() TO "anon";
GRANT ALL ON FUNCTION "public"."delete_old_profile"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."delete_old_profile"() TO "service_role";

GRANT ALL ON FUNCTION "public"."delete_storage_object"(bucket text, object text, OUT status integer, OUT content text) TO "anon";
GRANT ALL ON FUNCTION "public"."delete_storage_object"(bucket text, object text, OUT status integer, OUT content text) TO "authenticated";
GRANT ALL ON FUNCTION "public"."delete_storage_object"(bucket text, object text, OUT status integer, OUT content text) TO "service_role";

GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "service_role";

GRANT ALL ON TABLE "public"."posts" TO "anon";
GRANT ALL ON TABLE "public"."posts" TO "authenticated";
GRANT ALL ON TABLE "public"."posts" TO "service_role";

GRANT ALL ON SEQUENCE "public"."posts_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."posts_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."posts_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."profiles" TO "anon";
GRANT ALL ON TABLE "public"."profiles" TO "authenticated";
GRANT ALL ON TABLE "public"."profiles" TO "service_role";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "service_role";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "service_role";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "service_role";

RESET ALL;
