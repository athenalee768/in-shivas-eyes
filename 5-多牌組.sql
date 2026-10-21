-- 抽一張 Draw One:升級成「多牌組」架構(可重複執行)
-- 1) 牌組資料表  2) 牌卡加上所屬牌組欄位  3) 把目前的 In Shiva's Eyes 設為第一個牌組
create table if not exists public.draw_decks (
  slug text primary key,
  name text, name_en text, sub text, sub_en text,
  descr text, descr_en text,
  settings jsonb default '{}'::jsonb,
  sort int default 0,
  published boolean default true,
  created_at timestamptz default now()
);
alter table public.shiva_cards add column if not exists deck text default 'shiva';
update public.shiva_cards set deck = 'shiva' where deck is null;

alter table public.draw_decks enable row level security;
drop policy if exists "draw_decks_read" on public.draw_decks;
create policy "draw_decks_read" on public.draw_decks for select using (published or public.shiva_is_admin());
drop policy if exists "draw_decks_write" on public.draw_decks;
create policy "draw_decks_write" on public.draw_decks for all to authenticated using (public.shiva_is_admin()) with check (public.shiva_is_admin());

insert into public.draw_decks (slug,name,name_en,sub,sub_en,descr,descr_en,settings,sort,published) values
('shiva','In Shiva''s Eyes','In Shiva''s Eyes','神諭卡','Oracle Deck','由 Divinye Studio 創作的神諭卡,以濕婆的視角陪你看見內在的聲音。共 40 張,每張都有牌意與七個生活面向的解讀。','An oracle deck by Divinye Studio. Seen through Shiva’s eyes, the cards help you hear your inner voice, each with readings for seven areas of life.','{"bg": "images/bg.jpg", "back": "images/back.jpg", "cover": "images/cover.jpg", "god1": "images/brahma.jpg", "god2": "images/vishnu.jpg", "god3": "images/shiva.jpg"}'::jsonb,0,true)
on conflict (slug) do nothing;

-- 若你之前已在後台更換過圖片(存在 shiva_settings),一併合併進 shiva 牌組
update public.draw_decks d set settings = d.settings || coalesce((select jsonb_object_agg(key,value) from public.shiva_settings where coalesce(value,'') <> ''),'{}'::jsonb) where d.slug = 'shiva';
