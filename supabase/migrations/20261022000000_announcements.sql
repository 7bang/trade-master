-- 공지사항: 앱 설정 > 공지사항에서 언제든 확인, 중요 공지는 앱을 열 때 한 번 팝업.
-- 작성·수정·삭제는 관리자 웹페이지에서만 (admin_* 함수, 관리자 확인).
-- 읽음 기록은 서버에 저장 (기기를 바꿔도 같은 공지가 다시 뜨지 않게, 관리자는 읽은 수 확인).

CREATE TABLE IF NOT EXISTS public.announcements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL CHECK (char_length(title) BETWEEN 1 AND 100),
  body TEXT NOT NULL CHECK (char_length(body) BETWEEN 1 AND 5000),
  link_url TEXT CHECK (link_url IS NULL OR link_url ~ '^https://[^\s]+$'),
  link_label TEXT CHECK (link_label IS NULL OR char_length(link_label) BETWEEN 1 AND 30),
  is_important BOOLEAN NOT NULL DEFAULT false, -- true: 앱을 열 때 팝업
  is_published BOOLEAN NOT NULL DEFAULT false,
  published_at TIMESTAMPTZ,                    -- 처음 게시한 시각 (목록 정렬·표시)
  created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_announcements_published
  ON public.announcements (published_at DESC) WHERE is_published;

ALTER TABLE public.announcements ENABLE ROW LEVEL SECURITY;

-- 로그인한 사용자: 게시된 공지만 읽기 (쓰기 정책 없음 = 앱에서 작성 불가)
DROP POLICY IF EXISTS "Users can read published announcements" ON public.announcements;
CREATE POLICY "Users can read published announcements"
  ON public.announcements FOR SELECT
  TO authenticated
  USING (is_published AND published_at <= now());

REVOKE ALL ON public.announcements FROM anon;
REVOKE INSERT, UPDATE, DELETE ON public.announcements FROM authenticated;
GRANT SELECT ON public.announcements TO authenticated;

-- 읽음 기록: 본인 것만 읽고 남김
CREATE TABLE IF NOT EXISTS public.announcement_reads (
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  announcement_id UUID NOT NULL REFERENCES public.announcements(id) ON DELETE CASCADE,
  read_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, announcement_id)
);

ALTER TABLE public.announcement_reads ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read own announcement reads" ON public.announcement_reads;
CREATE POLICY "Users can read own announcement reads"
  ON public.announcement_reads FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can mark announcements read" ON public.announcement_reads;
CREATE POLICY "Users can mark announcements read"
  ON public.announcement_reads FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

REVOKE ALL ON public.announcement_reads FROM anon;
REVOKE UPDATE, DELETE ON public.announcement_reads FROM authenticated;
GRANT SELECT, INSERT ON public.announcement_reads TO authenticated;

-- ===== 관리자 (웹페이지) =====

-- 전체 공지 (숨김 포함) + 읽은 사람 수
CREATE OR REPLACE FUNCTION public.admin_announcements()
RETURNS TABLE (
  id UUID,
  title TEXT,
  body TEXT,
  link_url TEXT,
  link_label TEXT,
  is_important BOOLEAN,
  is_published BOOLEAN,
  published_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  read_count BIGINT
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  PERFORM public._require_admin();
  RETURN QUERY
  SELECT a.id, a.title, a.body, a.link_url, a.link_label, a.is_important, a.is_published,
         a.published_at, a.created_at, a.updated_at,
         (SELECT count(*) FROM announcement_reads r WHERE r.announcement_id = a.id)
  FROM announcements a
  ORDER BY COALESCE(a.published_at, a.created_at) DESC;
END;
$$;

-- 작성(p_id NULL) 또는 수정. 처음 게시할 때 published_at 기록
CREATE OR REPLACE FUNCTION public.admin_save_announcement(
  p_id UUID,
  p_title TEXT,
  p_body TEXT,
  p_link_url TEXT,
  p_link_label TEXT,
  p_is_important BOOLEAN,
  p_is_published BOOLEAN
)
RETURNS UUID
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_id UUID;
  v_link TEXT := NULLIF(btrim(COALESCE(p_link_url, '')), '');
  v_label TEXT := NULLIF(btrim(COALESCE(p_link_label, '')), '');
BEGIN
  PERFORM public._require_admin();

  IF v_link IS NOT NULL AND v_label IS NULL THEN
    v_label := '자세히 보기';
  END IF;
  IF v_link IS NULL THEN
    v_label := NULL;
  END IF;

  IF p_id IS NULL THEN
    INSERT INTO announcements (title, body, link_url, link_label, is_important, is_published,
                               published_at, created_by)
    VALUES (btrim(p_title), btrim(p_body), v_link, v_label, p_is_important, p_is_published,
            CASE WHEN p_is_published THEN now() END, auth.uid())
    RETURNING announcements.id INTO v_id;
  ELSE
    UPDATE announcements SET
      title = btrim(p_title),
      body = btrim(p_body),
      link_url = v_link,
      link_label = v_label,
      is_important = p_is_important,
      is_published = p_is_published,
      published_at = CASE WHEN p_is_published THEN COALESCE(published_at, now()) ELSE published_at END,
      updated_at = now()
    WHERE announcements.id = p_id
    RETURNING announcements.id INTO v_id;
    IF v_id IS NULL THEN
      RAISE EXCEPTION '공지를 찾을 수 없습니다';
    END IF;
  END IF;

  RETURN v_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_delete_announcement(p_id UUID)
RETURNS VOID
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  PERFORM public._require_admin();
  DELETE FROM announcements WHERE id = p_id;
END;
$$;

REVOKE ALL ON FUNCTION public.admin_announcements() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.admin_save_announcement(UUID, TEXT, TEXT, TEXT, TEXT, BOOLEAN, BOOLEAN) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.admin_delete_announcement(UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.admin_announcements() TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_save_announcement(UUID, TEXT, TEXT, TEXT, TEXT, BOOLEAN, BOOLEAN) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_delete_announcement(UUID) TO authenticated;
