--------START OF RXCUI SECTION---------
-- 11,876 rxcuis used by rxnorm,
--case when to have non null
--branded -> generic -> unquantified generic
--make view thats rxcui and makes it more general
select
  d.rxcui             rxnorm_concept_id,
  d.name              rxnorm_drug_name,
  d.prescribable_name prescribable_name,
  d.tty               rxnorm_term_type,
  dgm.non_quantified_rxcui unquantified_rxcui,
  (select d.name from drug_v d where d.rxcui = dgm.non_quantified_rxcui) unquantified_name,
  dgm.generic_rxcui generic_rxcui,
  (select d.name from drug_v d where d.rxcui = dgm.generic_rxcui) generic_name,
  dgm.generic_unquantified_rxcui generic_unquantified_rxcui,
  (select d.name from drug_v d where d.rxcui = dgm.generic_unquantified_rxcui) generic_unquantified_rxcui,
  (
    select coalesce(jsonb_agg(distinct two_part_ndc order by two_part_ndc), '[]'::jsonb)
    from mthspl_prod_ndc pnc
    where pnc.prod_rxaui in (
      select p.rxaui from mthspl_prod p where p.rxcui = d.rxcui
    )
  ) short_ndcs,
  (
    select coalesce(jsonb_agg(distinct code order by code), '[]'::jsonb)
    from mthspl_prod_mktcat_code mkc
    where mkc.prod_rxaui in (
      select p.rxaui from mthspl_prod p where p.rxcui = d.rxcui
    )
    and (mkc.mkt_cat like 'ANDA%' or mkc.mkt_cat like 'NDA%')
  ) application_codes,
  (
    select coalesce(jsonb_agg(distinct spl_set_id order by spl_set_id), '[]'::jsonb)
    from mthspl_prod_setid psi
    where psi.prod_rxaui in (
      select p.rxaui from mthspl_prod p where p.rxcui = d.rxcui
     )
  ) set_ids,
  (
    select coalesce(jsonb_agg(distinct rxp.name order by rxp.name), '[]'::jsonb)
    from mthspl_prod rxp
    where rxp.rxcui = d.rxcui
  ) product_names
from drug_v d
join drug_generalized_mv dgm on d.rxcui = dgm.rxcui
where exists(
        select 1 from mthspl_rxprod_v rxp where rxp.rxcui = d.rxcui
      )
;

--5,830 quantified human rx SCD
create or replace view mthspl_humanrx_generalized_scd_v as
select
  d.rxcui            rxnorm_concept_id,
  d.name             rxnorm_drug_name,
  d.prescribable_name prescribable_name,
  d.tty              rxnorm_term_type,
  dgm.non_quantified_rxcui unquantified_rxcui,
  (select d.name from drug_v d where d.rxcui = dgm.non_quantified_rxcui) unquantified_name,
  (
    select coalesce(jsonb_agg(distinct two_part_ndc order by two_part_ndc), '[]'::jsonb)
    from mthspl_prod_ndc pnc
    where pnc.prod_rxaui in (
      select p.rxaui from mthspl_prod p where p.rxcui = d.rxcui
    )
  ) short_ndcs,
  (
    select coalesce(jsonb_agg(distinct code order by code), '[]'::jsonb)
    from mthspl_prod_mktcat_code mkc
    where mkc.prod_rxaui in (
      select p.rxaui from mthspl_prod p where p.rxcui = d.rxcui
    )
    and (mkc.mkt_cat like 'ANDA%' or mkc.mkt_cat like 'NDA%')
  ) application_codes,
  (
    select coalesce(jsonb_agg(distinct spl_set_id order by spl_set_id), '[]'::jsonb)
    from mthspl_prod_setid psi
    where psi.prod_rxaui in (
      select p.rxaui from mthspl_prod p where p.rxcui = d.rxcui
     )
  ) set_ids,
  (
    select coalesce(jsonb_agg(distinct rxp.name order by rxp.name), '[]'::jsonb)
    from mthspl_prod rxp
    where rxp.rxcui = d.rxcui
  ) product_names
from drug_v d
join drug_generalized_mv dgm on d.rxcui = dgm.rxcui
where exists(
        select 1 from mthspl_rxprod_v rxp where rxp.rxcui = d.rxcui
      )
and d.tty = 'SCD'
and (d.quantified = 'Y' or d.quantified is null)
;

--human rx rxncuis from mthspl not in drug: 2,682
select
  rxp.rxcui,
  coalesce(jsonb_agg(distinct rxp.name), '[]'::jsonb)            product_names,
  coalesce(jsonb_agg(distinct rxp.short_ndc_codes), '[]'::jsonb) short_ndcs,
  coalesce(jsonb_agg(distinct rxp.set_ids), '[]'::jsonb)         set_ids,
  coalesce(jsonb_agg(distinct rxp.mkt_cat_codes), '[]'::jsonb)   appl_codes,
  coalesce(jsonb_agg(distinct rxp.label_types), '[]'::jsonb)     label_types
from mthspl_rxprod_v rxp
where rxp.rxcui not in (
  select rxcui from drug_v d
  )
group by rxp.rxcui
;

--human rx products from mthspl not in drug: 4,128
select *
from mthspl_rxprod_v
where rxcui not in (select rxcui from drug_v)
order by rxcui
;

--14,558 total rxcuis in rxprod
select distinct rxcui
from mthspl_rxprod_v rp
;

--56,334 total rxcuis in prod
select distinct rxcui
from mthspl_prod_v;
--------END OF RXCUI SECTION---------

------START OF APPL CODE SECTION-----
--800 distinct nda/anda codes have no product associated to an rxnorm drug
select distinct pmc.code
from mthspl_prod_mktcat_code pmc
where
  not exists (
    select 1
    from mthspl_prod p
    where p.rxaui = pmc.prod_rxaui
    and p.rxcui in (select d.rxcui from drug_v d)
  )
and (pmc.code like 'ANDA%' or pmc.code like 'NDA%')
and pmc.prod_rxaui in (
  select rxaui from mthspl_rxprod_v
  )
;

--12,137
select *
from mthspl_mktcode_rxprod_drug_v mrd
;

--5,473
select *
from mthspl_mktcode_rxprod_drug_v mrd
where jsonb_array_length(mrd.generic_names) > 1
;

--6,328
select *
from mthspl_mktcode_rxprod_drug_v mrd
where jsonb_array_length(mrd.generic_names) = 1
and mrd.generic_names <> '[]'::jsonb
;
-----END OF APPL CODE SECTION--------

-----START OF NDC SECTION-------
--2,957 distinct short ndc codes have no product associated to an rxnorm drug
select distinct pn.two_part_ndc short_ndc
from mthspl_prod_ndc pn
where
  not exists (
    select 1
    from mthspl_prod p
    where p.rxaui = pn.prod_rxaui
    and p.rxcui in (select d.rxcui from drug_v d)
  )
and pn.prod_rxaui in (
  select rxp.rxaui from mthspl_rxprod_v rxp
  )
;

--68,816
select *
from mthspl_ndc_rxprod_drug_v
;

-- 63,351
select *
from mthspl_ndc_rxprod_drug_v nrd
where jsonb_array_length(nrd.generic_names) = 1
and nrd.generic_names <> '[]'::jsonb
;

--436
select *
from mthspl_ndc_rxprod_drug_v nrd
where jsonb_array_length(nrd.generic_names) > 1
;

------END OF NDC SECTION-----

------START OF SET ID SECTION------
--2,794 distinct setids have no product associated to an rxnorm drug
select distinct ps.spl_set_id set_id
from mthspl_prod_setid ps
where
  not exists (
    select 1
    from mthspl_prod p
    where p.rxaui = ps.prod_rxaui
    and p.rxcui in (select d.rxcui from drug_v d)
  )
and ps.prod_rxaui in (
  select rxp.rxaui from mthspl_rxprod_v rxp
  )
;

--30,186
select *
from mthspl_rxprod_setid_drug_v rsd
where jsonb_array_length(rsd.generic_names) = 1
and rsd.generic_names <> '[]'::jsonb
;

--11,045
select *
from mthspl_rxprod_setid_drug_v rsd
where jsonb_array_length(rsd.generic_names) > 1
;

--43,445
select *
from mthspl_rxprod_setid_drug_v rsd
;
------END OF SET ID SECTION--------

--ingredient level
select * from ingrset where name like '%abacavir%';
select * from ingrset where name like '%azithromycin%';
--component level
select * from scdc where name like '%abacavir%';
select * from scdc where name like '%azithromycin%';
--drug dose form level
select * from scdf where name like '%abacavir%';
select * from scdf where name like '%azithromycin%';
--drug dose form group level
select * from scdg where name like '%abacavir%';
select * from scdg where name like '%azithromycin%';
--drug level
select * from scd_prod_v where rxnorm_drug_name ilike '%abacavir%';
select * from scd_prod_v where rxnorm_drug_name like '%azithromycin%';

select i.rxcui, i.name, scdc.*, scd_prod_v.*
from ingr i
join scdc on scdc.ingr_rxcui = i.rxcui
join scdc_scd on scdc_scd.scdc_rxcui = scdc.rxcui
join scd_prod_v on scd_prod_v.rxnorm_concept_id = scdc_scd.scd_rxcui
where i.name like '%abacavir%'
;

select i.rxcui, i.name, s.*, scd_prod_v.*
from ingr i
join scdf_ingr si on i.rxcui = si.ingr_rxcui
join scdf s on si.scdf_rxcui = s.rxcui
join scdf_scd ss on s.rxcui = ss.scdf_rxcui
join scd_prod_v on scd_prod_v.rxnorm_concept_id = ss.scd_rxcui
where i.name like '%abacavir%';

select i.rxcui, i.name, scdg.*, scd_prod_v.*
from ingr i
join scdg_ingr si on si.ingr_rxcui = i.rxcui
join scdg on scdg.rxcui = si.scdg_rxcui
join scdg_scd ss on scdg.rxcui = ss.scdg_rxcui
join scd_prod_v on scd_prod_v.rxnorm_concept_id = ss.scd_rxcui
where i.name like '%abacavir%';


create or replace view scd_prod_v as
select
  d.rxcui             rxnorm_concept_id,
  d.name              rxnorm_drug_name,
  d.prescribable_name as prescribable_name,
  dgm.non_quantified_rxcui unquantified_rxcui,
  (select d.name from drug_v d where d.rxcui = dgm.non_quantified_rxcui) unquantified_name,
  d.ingrset_rxcui,
  (
    select coalesce(jsonb_agg(distinct suv.unii), '[]'::jsonb)
    from scd_unii_v suv
    where suv.scd_rxcui = d.rxcui
  ) uniis,
  (select df.name from df where df.rxcui = d.df_rxcui),
  d.rxterm_form,
  d.avail_strengths,
  d.qual_distinct, d.quantity, d.human_drug, d.vet_drug,
  (
    select coalesce(jsonb_agg(distinct two_part_ndc order by two_part_ndc), '[]'::jsonb)
    from mthspl_prod_ndc pnc
    where pnc.prod_rxaui in (
      select p.rxaui from mthspl_rxprod_v p where p.rxcui = d.rxcui
    )
  ) short_ndcs,
  (
    select coalesce(jsonb_agg(distinct uniis_str(pnc.prod_rxaui)), '[]'::jsonb)
    from mthspl_prod_ndc pnc
    where pnc.prod_rxaui in (
      select p.rxaui from mthspl_rxprod_v p where p.rxcui = d.rxcui
    )
  ) short_ndc_uniis,
  (
    select coalesce(jsonb_agg(distinct code order by code), '[]'::jsonb)
    from mthspl_prod_mktcat_code mkc
    where mkc.prod_rxaui in (
      select p.rxaui from mthspl_rxprod_v p where p.rxcui = d.rxcui
    )
    and (mkc.mkt_cat like 'ANDA%' or mkc.mkt_cat like 'NDA%')
  ) application_codes,
  (
    select coalesce(jsonb_agg(distinct spl_set_id order by spl_set_id), '[]'::jsonb)
    from mthspl_prod_setid psi
    where psi.prod_rxaui in (
      select p.rxaui from mthspl_rxprod_v p where p.rxcui = d.rxcui
     )
  ) set_ids,
  (
    select coalesce(jsonb_agg(distinct rxp.name order by rxp.name), '[]'::jsonb)
    from mthspl_rxprod_v rxp
    where rxp.rxcui = d.rxcui
  ) product_names
from scd d
join drug_generalized_mv dgm on d.rxcui = dgm.rxcui
where exists(
        select 1 from mthspl_rxprod_v rxp where rxp.rxcui = d.rxcui
)
;

--azithromycin
--abacavir