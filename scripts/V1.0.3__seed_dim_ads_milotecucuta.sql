-- ────────────────────────────────────────────────────────────────────────
-- V1.0.3 — Seed dim_ads: Milotecucuta (Meta Ads Manager export)
-- Generado: 2026-05-22T03:22:19.308Z
-- 107 anuncios unicos | account_id: 1177096264190146
--
-- Antes de ejecutar, obtener location_id real con:
--   SELECT DISTINCT location_id FROM dim_contacts LIMIT 5;
-- Reemplazar REEMPLAZAR_CON_LOCATION_ID_DE_GHL con ese valor.
-- ────────────────────────────────────────────────────────────────────────

DO $$
DECLARE loc TEXT := '0IP2MEmSx0fpdVllDK5b';
BEGIN

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120224289771820527', 'CÚCUTA MIRAFLOR', '120224289771840527', 'CÚCUTA MIRAFLOR', '120224289771830527', 'CÚCUTA MIRAFLOR', '1177096264190146', loc, 'Reconocimiento', 10000, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120225088933710527', 'INTERACCIÓN LOTES DESDE 20 M', '120225088933700527', 'INTERACCIÓN LOTES DESDE 20 M', '120225088933690527', 'INTERACCIÓN LOTES DESDE 20 M', '1177096264190146', loc, 'Interacción', 30000, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120225439233560527', 'INTERACCIÓN UBICACIÓN', '120225439233580527', 'INTERACCIÓN UBICACIÓN', '120225439233570527', 'INTERACCIÓN UBICACIÓN', '1177096264190146', loc, 'Interacción', 30000, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120225887993240527', 'VENDEDOR CÚCUTA', '120225887993140527', 'VENDEDOR CÚCUTA', '120225887993090527', 'VENDEDOR CÚCUTA', '1177096264190146', loc, 'Interacción', 15000, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120226369042820527', 'INTERACCIÓN AGUA', '120226369042830527', 'INTERACCIÓN ISAAC', '120226369042810527', 'INTERACCIÓN ISAAC', '1177096264190146', loc, 'Interacción', 15000, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120226442768740527', 'VENDEDOR CÚCUTA 2', '120226442768720527', 'VENDEDOR CÚCUTA 2', '120226442768730527', 'VENDEDOR CÚCUTA 2', '1177096264190146', loc, 'Interacción', 10000, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120226628932130527', 'VENDEDOR NUEVA', '120226628932140527', 'VENDEDOR NUEVA', '120226628932150527', 'VENDEDOR NUEVA', '1177096264190146', loc, 'Interacción', 10000, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120226679770030527', 'INTERACCIÓN PRIMA', '120226679770040527', 'INTERACCIÓN PRIMA', '120226679770020527', 'INTERACCIÓN PRIMA', '1177096264190146', loc, 'Interacción', 15000, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120226973372340527', 'Reconocimiento cuidado con las estafas', '120226973372330527', 'Reconocimiento cuidado con las estafas', '120226973372350527', 'Reconocimiento cuidado con las estafas', '1177096264190146', loc, 'Reconocimiento', 30000, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120228235151300527', 'INTERACCIÓN EN MI LOTE ES FÁCIL', '120228235151290527', 'INTERACCIÓN EN MI LOTE ES FÁCIL', '120228235151280527', 'INTERACCIÓN EN MI LOTE ES FÁCIL', '1177096264190146', loc, 'Interacción', NULL, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120228293618500527', 'INTERACCIÓN TODA LA VIDA PAGANDO ARRIENDO', '120228293618510527', 'INTERACCIÓN TODA LA VIDA PAGANDO ARRIENDO', '120228293618520527', 'INTERACCIÓN TODA LA VIDA PAGANDO ARRIENDO', '1177096264190146', loc, 'Interacción', NULL, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120228397125910527', 'Interacción FERIAS', '120228397125920527', 'Interacción FERIAS', '120228397125930527', 'Interacción FERIAS', '1177096264190146', loc, 'Interacción', NULL, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120229670772160527', 'TRÁFICO TODA LA VIDA PAGANDO ARRIENDO', '120229670772180527', 'TRÁFICO TODA LA VIDA PAGANDO ARRIENDO', '120229670772170527', 'TRÁFICO TODA LA VIDA PAGANDO ARRIENDO', '1177096264190146', loc, 'Tráfico', 10000, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120229672401730527', 'TRÁFICO VOX POPULI', '120229672401750527', 'TRÁFICO VOX POPULI', '120229672401740527', 'TRÁFICO VOX POPULI', '1177096264190146', loc, 'Tráfico', 10000, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120229913657870527', 'INTERACCIÓN invertir en un lote urbano no es un sueño', '120229913657890527', 'INTERACCIÓN invertir en un lote urbano no es un sueño', '120229913657880527', 'INTERACCIÓN invertir en un lote urbano no es un sueño', '1177096264190146', loc, 'Interacción', NULL, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120229914154490527', 'INTERACCIÓN Convertir 500 mil en 50 millones', '120229914154480527', 'INTERACCIÓN Convertir 500 mil en 50 millones', '120229914154470527', 'INTERACCIÓN Convertir 500 mil en 50 millones', '1177096264190146', loc, 'Interacción', NULL, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120229914517770527', 'TRÁFICO el futbol no te hacer rico invertir sí', '120229914517790527', 'TRÁFICO el futbol no te hacer rico invertir sí', '120229914517780527', 'TRÁFICO el futbol no te hacer rico invertir sí', '1177096264190146', loc, 'Tráfico', 10000, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120230465036030527', 'Interacción iniciamos obra de nuestros proyectos', '120230465036050527', 'Interacción iniciamos obra de nuestros proyectos', '120230465036040527', 'Interacción iniciamos obra de nuestros proyectos', '1177096264190146', loc, 'Interacción', NULL, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120230872535510527', 'Tráfico Invertir no es solo para los ultraricos', '120230872535490527', 'Tráfico Invertir no es solo para los ultraricos', '120230872535500527', 'Tráfico Invertir no es solo para los ultraricos', '1177096264190146', loc, 'Tráfico', 10000, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120230874446880527', 'Denver Interacción comprar un lote aquí es sencillo', '120230874446900527', 'Denver Interacción comprar un lote aquí es sencillo', '120230874446890527', 'Interacción comprar un lote aquí es sencillo', '1177096264190146', loc, 'Interacción', NULL, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120230874598710527', 'Chicago Interacción comprar un lote aquí es sencillo', '120230874598720527', 'Chicago Interacción comprar un lote aquí es sencillo', '120230874446890527', 'Interacción comprar un lote aquí es sencillo', '1177096264190146', loc, 'Interacción', NULL, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120230874622310527', 'Denver Interacción invertir en un lote urbano no es un sueño', '120230874622330527', 'Denver Interacción invertir en un lote urbano no es un sueño', '120230874622320527', 'Interacción invertir en un lote urbano no es un sueño', '1177096264190146', loc, 'Interacción', NULL, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120230874751000527', 'Chicago Interacción invertir en un lote urbano no es un sueño', '120230874751010527', 'Chicago Interacción invertir en un lote urbano no es un sueño', '120230874622320527', 'Interacción invertir en un lote urbano no es un sueño', '1177096264190146', loc, 'Interacción', NULL, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120230874804040527', 'DENVER INTERACCIÓN UBICACIÓN', '120230874804050527', 'DENVER INTERACCIÓN UBICACIÓN', '120225439233570527', 'INTERACCIÓN UBICACIÓN', '1177096264190146', loc, 'Interacción', 20000, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120230874890720527', 'CHICAGO INTERACCIÓN UBICACIÓN', '120230874890730527', 'CHICAGO INTERACCIÓN UBICACIÓN', '120225439233570527', 'INTERACCIÓN UBICACIÓN', '1177096264190146', loc, 'Interacción', 20000, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120231072095610527', 'Interacción tu terreno por menos que un arriendo', '120231072095630527', 'Interacción tu terreno por menos que un arriendo', '120231072095620527', 'Interacción tu terreno por menos que un arriendo', '1177096264190146', loc, 'Interacción', NULL, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120231072205530527', 'Tráfico que tu lote quede 100% a tu nombre', '120231072205510527', 'Tráfico que tu lote quede 100% a tu nombre', '120231072205520527', 'Tráfico que tu lote quede 100% a tu nombre', '1177096264190146', loc, 'Tráfico', 15000, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120231259187050527', 'Interacción asegura tu futuro', '120231259187070527', 'Interacción asegura tu futuro', '120231259187060527', 'Interacción asegura tu futuro', '1177096264190146', loc, 'Interacción', NULL, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120231259444110527', 'Interacción sorprende con un lote', '120231259444120527', 'Interacción sorprende con un lote', '120231259444130527', 'Interacción sorprende con un lote', '1177096264190146', loc, 'Interacción', NULL, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120231321317730527', 'Interacción lote urbano junto a una universidad', '120231321317720527', 'Interacción lote urbano junto a una universidad', '120231321317740527', 'Interacción lote urbano junto a una universidad', '1177096264190146', loc, 'Interacción', NULL, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120231689090330527', 'INTERACCIÓN EN MI LOTE ES FÁCIL', '120231689090320527', 'INTERACCIÓN EN MI LOTE ES FÁCIL', '120228235151280527', 'INTERACCIÓN EN MI LOTE ES FÁCIL', '1177096264190146', loc, 'Interacción', NULL, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120231689230720527', 'Interacción lote urbano junto a una universidad', '120231689230730527', 'Interacción lote urbano junto a una universidad', '120231321317740527', 'Interacción lote urbano junto a una universidad', '1177096264190146', loc, 'Interacción', NULL, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120231689302700527', 'Interacción sorprende con un lote', '120231689302710527', 'Interacción sorprende con un lote', '120231259444130527', 'Interacción sorprende con un lote', '1177096264190146', loc, 'Interacción', NULL, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120231690880270527', 'Interacción asegura tu futuro', '120231690880280527', 'Interacción asegura tu futuro', '120231259187060527', 'Interacción asegura tu futuro', '1177096264190146', loc, 'Interacción', NULL, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120231691453610527', 'INTERACCIÓN Convertir 500 mil en 50 millones', '120231691453620527', 'INTERACCIÓN Convertir 500 mil en 50 millones', '120229914154470527', 'INTERACCIÓN Convertir 500 mil en 50 millones', '1177096264190146', loc, 'Interacción', NULL, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120231694437800527', 'INTERACCIÓN UBICACIÓN', '120231694437810527', 'INTERACCIÓN UBICACIÓN', '120225439233570527', 'INTERACCIÓN UBICACIÓN', '1177096264190146', loc, 'Interacción', 30000, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120231699161250527', 'Interacción lote urbano junto a una universidad', '120231699161260527', 'Interacción lote urbano junto a una universidad', '120231321317740527', 'Interacción lote urbano junto a una universidad', '1177096264190146', loc, 'Interacción', NULL, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120231699328480527', 'Interacción sorprende con un lote', '120231699328490527', 'Interacción sorprende con un lote', '120231259444130527', 'Interacción sorprende con un lote', '1177096264190146', loc, 'Interacción', NULL, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120231699423350527', 'Interacción asegura tu futuro', '120231699423360527', 'Interacción asegura tu futuro', '120231259187060527', 'Interacción asegura tu futuro', '1177096264190146', loc, 'Interacción', NULL, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120231699493910527', 'INTERACCIÓN Convertir 500 mil en 50 millones', '120231699493920527', 'INTERACCIÓN Convertir 500 mil en 50 millones', '120229914154470527', 'INTERACCIÓN Convertir 500 mil en 50 millones', '1177096264190146', loc, 'Interacción', NULL, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120231699598470527', 'INTERACCIÓN EN MI LOTE ES FÁCIL', '120231699598480527', 'INTERACCIÓN EN MI LOTE ES FÁCIL', '120228235151280527', 'INTERACCIÓN EN MI LOTE ES FÁCIL', '1177096264190146', loc, 'Interacción', NULL, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120231699665590527', 'INTERACCIÓN UBICACIÓN', '120231699665600527', 'INTERACCIÓN UBICACIÓN', '120225439233570527', 'INTERACCIÓN UBICACIÓN', '1177096264190146', loc, 'Interacción', 30000, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120231751158320527', 'CHICAGO Interacción no importa dónde estés, invierte en Colombia', '120231751158330527', 'CHICAGO Interacción  invierte en Colombia desde el exterior', '120231750785320527', 'Interacción invierte en Colombia desde el exterior', '1177096264190146', loc, 'Interacción', NULL, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120231751254780527', 'DENVER Interacción no importa dónde estés, invierte en Colombia', '120231751254790527', 'DENVER Interacción  invierte en Colombia desde el exterior', '120231750785320527', 'Interacción invierte en Colombia desde el exterior', '1177096264190146', loc, 'Interacción', NULL, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120231874562640527', 'Interacción MARKETPLACE CARRUSEL', '120231874562620527', 'Interacción MARKETPLACE CARRUSEL', '120231874562630527', 'Interacción MARKETPLACE', '1177096264190146', loc, 'Interacción', NULL, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120231875339680527', 'Interacción MARKETPLACE Interacción MARKETPLACE 1 IMAGEN', '120231875339690527', 'Interacción MARKETPLACE 1 IMAGEN', '120231874562630527', 'Interacción MARKETPLACE', '1177096264190146', loc, 'Interacción', NULL, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120231876309470527', 'Clientes potenciales FORMULARIO', '120231876309490527', 'Clientes potenciales FORMULARIO', '120231876309480527', 'Clientes potenciales FORMULARIO', '1177096264190146', loc, 'Clientes potenciales', 30000, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120232267675610527', 'Tráfico esto es valorización', '120232267675590527', 'Tráfico esto es valorización', '120232267675600527', 'Tráfico esto es valorización', '1177096264190146', loc, 'Tráfico', 10000, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120232360854630527', 'ASESOR EN VENTAS', '120232360854650527', 'ASESOR EN VENTAS', '120232360854640527', 'ASESOR EN VENTAS', '1177096264190146', loc, 'Interacción', 10000, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120237778925900527', 'Cúcuta - Nos han preguntado mucho 15 k', '120237778925910527', 'Cúcuta - Nos han preguntado mucho 15 k', '120237778925920527', 'Nos han preguntado mucho 15 k', '1177096264190146', loc, 'Interacción', 40000, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120237856287440527', 'Cúcuta - 50 millones 15 k', '120237856287450527', 'Cúcuta - 50 millones 15 k', '120237856287430527', '50 millones  15 k', '1177096264190146', loc, 'Interacción', 40000, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120237857005670527', 'Cúcuta - Comprar lote 15 k', '120237857005690527', 'Cúcuta - Comprar lote 15 k', '120237857005680527', 'Comprar lote 15 k', '1177096264190146', loc, 'Interacción', 40000, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120239015166620527', 'Planos casa', '120239015166630527', 'Te entregamos los planos_Miravista Público Abierto', '120239015166610527', 'Campaña Febrero_Miravista', '1177096264190146', loc, 'Interacción', 20000, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120239015941870527', 'Invierte en valorización', '120239015166630527', 'Te entregamos los planos_Miravista Público Abierto', '120239015166610527', 'Campaña Febrero_Miravista', '1177096264190146', loc, 'Interacción', 20000, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120239082315800527', 'Planos edificio', '120239015166630527', 'Te entregamos los planos_Miravista Público Abierto', '120239015166610527', 'Campaña Febrero_Miravista', '1177096264190146', loc, 'Interacción', 20000, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120239082373030527', 'Cuota $500.000', '120239015166630527', 'Te entregamos los planos_Miravista Público Abierto', '120239015166610527', 'Campaña Febrero_Miravista', '1177096264190146', loc, 'Interacción', 20000, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120239224307670527', 'Así puede ser tu casa', '120237778925910527', 'Cúcuta - Nos han preguntado mucho 15 k', '120237778925920527', 'Nos han preguntado mucho 15 k', '1177096264190146', loc, 'Interacción', 40000, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120239224414330527', 'LOTES_ANIMACIÓN CASAS', '120239015166630527', 'Te entregamos los planos_Miravista Público Abierto', '120239015166610527', 'Campaña Febrero_Miravista', '1177096264190146', loc, 'Interacción', 20000, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120239513481950527', 'ASÍ PUEDE SER TU CASA', '120239015166630527', 'Te entregamos los planos_Miravista Público Abierto', '120239015166610527', 'Campaña Febrero_Miravista', '1177096264190146', loc, 'Interacción', 20000, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120239518087280527', 'IMAGEN LOTES', '120239015166630527', 'Te entregamos los planos_Miravista Público Abierto', '120239015166610527', 'Campaña Febrero_Miravista', '1177096264190146', loc, 'Interacción', 20000, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120239541736340527', 'Cuota $500.000', '120239541736360527', 'Te entregamos los planos_Miravista - Público por intereses', '120239015166610527', 'Campaña Febrero_Miravista', '1177096264190146', loc, 'Interacción', 20000, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120239541736370527', 'ASÍ PUEDE SER TU CASA', '120239541736360527', 'Te entregamos los planos_Miravista - Público por intereses', '120239015166610527', 'Campaña Febrero_Miravista', '1177096264190146', loc, 'Interacción', 20000, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120239541736400527', 'Invierte en valorización', '120239541736360527', 'Te entregamos los planos_Miravista - Público por intereses', '120239015166610527', 'Campaña Febrero_Miravista', '1177096264190146', loc, 'Interacción', 20000, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120239541736410527', 'IMAGEN LOTES', '120239541736360527', 'Te entregamos los planos_Miravista - Público por intereses', '120239015166610527', 'Campaña Febrero_Miravista', '1177096264190146', loc, 'Interacción', 20000, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120240176288670527', 'ELLOS YA COMPRARON', '120240176288660527', 'RESERVA MIRAVISTA_PÚBLICO ABIERTO', '120240176288630527', 'RESERVA MIRAVISTA_PÚBLICO ABIERTO', '1177096264190146', loc, 'Interacción', NULL, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120240176521820527', 'NO NECESITAS PRESTAMOS', '120240176288660527', 'RESERVA MIRAVISTA_PÚBLICO ABIERTO', '120240176288630527', 'RESERVA MIRAVISTA_PÚBLICO ABIERTO', '1177096264190146', loc, 'Interacción', NULL, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120240249357970527', '¿SI ES REAL?_LAURA', '120240249358000527', 'RESERVA MIRAVISTA_PÚBLICO x INTERESES', '120240249357980527', 'RESERVA MIRAVISTA_PÚBLICO x INTERESES', '1177096264190146', loc, 'Interacción', NULL, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120240264312890527', 'LOTE PLANO', '120240264312870527', 'UN LOTE PLANO_PÚBLICO ABIERTO', '120240264312880527', 'UN LOTE PLANO_PÚBLICO ABIERTO', '1177096264190146', loc, 'Ventas', NULL, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120240264583540527', 'NO COMPRES SIN SABER ESTO', '120240264312870527', 'UN LOTE PLANO_PÚBLICO ABIERTO', '120240264312880527', 'UN LOTE PLANO_PÚBLICO ABIERTO', '1177096264190146', loc, 'Ventas', NULL, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120240264649630527', 'LOTES DESDE 52K_MAYRON', '120240264312870527', 'UN LOTE PLANO_PÚBLICO ABIERTO', '120240264312880527', 'UN LOTE PLANO_PÚBLICO ABIERTO', '1177096264190146', loc, 'Ventas', NULL, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120240384430320527', 'LA SEÑAL', '120240384430310527', 'RESERVA MIRAVISTA_PÚBLICO ABIERTO_CONSTRUCTORES', '120240384430300527', 'RESERVA MIRAVISTA_PÚBLICO ABIERTO_CONSTRUCTORES', '1177096264190146', loc, 'Interacción', NULL, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120241004340150527', 'LA SEÑAL QUE ESPERABAS', '120241004340170527', 'PRUEBA SIXTEAM', '120241004340160527', 'CP | AGENDAMIENTO', '1177096264190146', loc, 'Clientes potenciales', NULL, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120241004902540527', 'LOTE PLANO', '120241004340170527', 'PRUEBA SIXTEAM', '120241004340160527', 'CP | AGENDAMIENTO', '1177096264190146', loc, 'Clientes potenciales', NULL, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120241004933210527', 'LOTES DESDE 52MILLONES', '120241004340170527', 'PRUEBA SIXTEAM', '120241004340160527', 'CP | AGENDAMIENTO', '1177096264190146', loc, 'Clientes potenciales', NULL, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120242046620590527', 'QUE PUEDES HACER EN UN LOTE?', '120241004340170527', 'PRUEBA SIXTEAM', '120241004340160527', 'CP | AGENDAMIENTO', '1177096264190146', loc, 'Clientes potenciales', NULL, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120224453016920527', 'FORMULARIO 1', '120224453016930527', 'FORMULARIO 1', '120224453016940527', 'FORMULARIO 1', '1177096264190146', loc, 'Clientes potenciales', 15000, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120242047381690527', 'LA SEÑAL QUE ESTABAS ESPERANDO', '120241004340170527', 'PRUEBA SIXTEAM', '120241004340160527', 'CP | AGENDAMIENTO', '1177096264190146', loc, 'Clientes potenciales', NULL, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120242047983380527', 'ENTREVISTA PARQUE SANTANDER', '120242047983370527', 'PÚBLICO ABIERTO', '120242047983360527', 'TRÁFICO SEGUIDORES IG', '1177096264190146', loc, 'Tráfico', NULL, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120242121267640527', 'Ad 1 | Reel | Firmar a Ciegas', '120242047983370527', 'PÚBLICO ABIERTO', '120242047983360527', 'TRÁFICO SEGUIDORES IG', '1177096264190146', loc, 'Tráfico', NULL, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120242121850790527', 'TODOS PREGUNTAN', '120242121850820527', 'PÚBLICO POR INTERESES', '120242121850760527', 'TODOS PREGUNTAN', '1177096264190146', loc, 'Clientes potenciales', NULL, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120242122580990527', 'LOTES URBANOS', '120242122580970527', 'PÚBLICO POR INTERESES', '120242122580980527', 'LOTES URBANOS', '1177096264190146', loc, 'Clientes potenciales', NULL, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120242123206010527', 'NO COMPRES SIN SABER ESTO', '120242123206020527', 'PÚBLICO POR INTERESES', '120242123206000527', 'NO COMPRES SIN SABER ESTO', '1177096264190146', loc, 'Clientes potenciales', NULL, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120243153023160527', 'Ad 5 | Reel | Esta es la señal', '120243153023150527', 'CP | AGENDAMIENTO', '120241004340160527', 'CP | AGENDAMIENTO', '1177096264190146', loc, 'Clientes potenciales', NULL, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120243153023170527', 'Ad 4 | Reel | QUE PUEDES HACER EN UN LOTE?', '120243153023150527', 'CP | AGENDAMIENTO', '120241004340160527', 'CP | AGENDAMIENTO', '1177096264190146', loc, 'Clientes potenciales', NULL, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120243163867750527', 'Ad 1 | Reel | Ser parte del proyecto', '120243163867760527', 'RMKTG | IG interacciones', '120243163867740527', 'Reconocimiento', '1177096264190146', loc, 'Reconocimiento', 5000, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120243167873010527', 'Ad 1 | Reel | Comprar lote en 2026 sí se puede', '120243153023150527', 'CP | AGENDAMIENTO', '120241004340160527', 'CP | AGENDAMIENTO', '1177096264190146', loc, 'Clientes potenciales', NULL, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120243294299150527', 'Ad 1 | Reel | Comprar lote en 2026 sí se puede', '120243294299160527', 'CP | WhatsApp | Agenda | SIMILARES %2', '120243294299140527', 'CP | WhatsApp | Agendamiento', '1177096264190146', loc, 'Clientes potenciales', 20000, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120243369338460527', 'Ad 2 | Reel | Firmar a Ciegas', '120243294299160527', 'CP | WhatsApp | Agenda | SIMILARES %2', '120243294299140527', 'CP | WhatsApp | Agendamiento', '1177096264190146', loc, 'Clientes potenciales', 20000, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120243370323240527', 'Ad 3 | Reel |  Estos son los lotes', '120243294299160527', 'CP | WhatsApp | Agenda | SIMILARES %2', '120243294299140527', 'CP | WhatsApp | Agendamiento', '1177096264190146', loc, 'Clientes potenciales', 20000, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120243371061470527', 'Ad 4 | Reel | QUE PUEDES HACER EN UN LOTE?', '120243294299160527', 'CP | WhatsApp | Agenda | SIMILARES %2', '120243294299140527', 'CP | WhatsApp | Agendamiento', '1177096264190146', loc, 'Clientes potenciales', 20000, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120243379196210527', 'Ad 5 | Reel | Esta es la señal', '120243294299160527', 'CP | WhatsApp | Agenda | SIMILARES %2', '120243294299140527', 'CP | WhatsApp | Agendamiento', '1177096264190146', loc, 'Clientes potenciales', 20000, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120243554543270527', 'Ad 2 | Reel | Firmar a Ciegas', '120243153023150527', 'CP | AGENDAMIENTO', '120241004340160527', 'CP | AGENDAMIENTO', '1177096264190146', loc, 'Clientes potenciales', NULL, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120243555128730527', 'Ad 3 | Reel |  Estos son los lotes', '120243153023150527', 'CP | AGENDAMIENTO', '120241004340160527', 'CP | AGENDAMIENTO', '1177096264190146', loc, 'Clientes potenciales', NULL, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120243555343470527', 'FIRMAR A CIEGAS', '120243555343460527', 'RMKTG | IG | Visita al Perfil', '120242047983360527', 'TRÁFICO SEGUIDORES IG', '1177096264190146', loc, 'Tráfico', NULL, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120243790849860527', 'Ad 6 | Reel | Valor de la tierra', '120243153023150527', 'CP | AGENDAMIENTO', '120241004340160527', 'CP | AGENDAMIENTO', '1177096264190146', loc, 'Clientes potenciales', NULL, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120243791155610527', 'Ad 6 | Reel | Valor de la tierra', '120243294299160527', 'CP | WhatsApp | Agenda | SIMILARES %2', '120243294299140527', 'CP | WhatsApp | Agendamiento', '1177096264190146', loc, 'Clientes potenciales', 20000, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120243791723200527', 'Ad 1 | Reel | Ser parte del proyecto', '120243555343460527', 'RMKTG | IG | Visita al Perfil', '120242047983360527', 'TRÁFICO SEGUIDORES IG', '1177096264190146', loc, 'Tráfico', NULL, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120243791780720527', 'Ad 2 | Reel | Evento Dia de la Madre', '120243555343460527', 'RMKTG | IG | Visita al Perfil', '120242047983360527', 'TRÁFICO SEGUIDORES IG', '1177096264190146', loc, 'Tráfico', NULL, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120243792945960527', 'Ad 7 | Reel | Ultimos Lotes', '120243153023150527', 'CP | AGENDAMIENTO', '120241004340160527', 'CP | AGENDAMIENTO', '1177096264190146', loc, 'Clientes potenciales', NULL, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120243793621780527', 'Ad 7 | Reel | Ultimos Lotes', '120243294299160527', 'CP | WhatsApp | Agenda | SIMILARES %2', '120243294299140527', 'CP | WhatsApp | Agendamiento', '1177096264190146', loc, 'Clientes potenciales', 20000, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120239541736350527', 'Planos edificio', '120239541736360527', 'Te entregamos los planos_Miravista - Público por intereses', '120239015166610527', 'Campaña Febrero_Miravista', '1177096264190146', loc, 'Interacción', 20000, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120239541736380527', 'Planos casa', '120239541736360527', 'Te entregamos los planos_Miravista - Público por intereses', '120239015166610527', 'Campaña Febrero_Miravista', '1177096264190146', loc, 'Interacción', 20000, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120239541736390527', 'LOTES_ANIMACIÓN CASAS', '120239541736360527', 'Te entregamos los planos_Miravista - Público por intereses', '120239015166610527', 'Campaña Febrero_Miravista', '1177096264190146', loc, 'Interacción', 20000, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120243153023180527', 'LOTES DESDE 52MILLONES', '120243153023150527', 'CP | AGENDAMIENTO', '120241004340160527', 'CP | AGENDAMIENTO', '1177096264190146', loc, 'Clientes potenciales', NULL, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120243153023190527', 'LOTE PLANO', '120243153023150527', 'CP | AGENDAMIENTO', '120241004340160527', 'CP | AGENDAMIENTO', '1177096264190146', loc, 'Clientes potenciales', NULL, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120243153023200527', 'LA SEÑAL QUE ESPERABAS', '120243153023150527', 'CP | AGENDAMIENTO', '120241004340160527', 'CP | AGENDAMIENTO', '1177096264190146', loc, 'Clientes potenciales', NULL, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();

  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES ('120243555343480527', 'ENTREVISTA PARQUE SANTANDER', '120243555343460527', 'RMKTG | IG | Visita al Perfil', '120242047983360527', 'TRÁFICO SEGUIDORES IG', '1177096264190146', loc, 'Tráfico', NULL, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();
END $$;

-- Verificacion post-carga:
-- SELECT COUNT(*), location_id FROM dim_ads GROUP BY location_id;
-- SELECT ad_id, ad_name, adset_name, campaign_name FROM dim_ads ORDER BY synced_at DESC LIMIT 10;
-- REFRESH MATERIALIZED VIEW CONCURRENTLY mv_unified_attribution;