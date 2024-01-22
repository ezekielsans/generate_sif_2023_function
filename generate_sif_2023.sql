-- Function: public.generate_sif_2023(date, date)

-- DROP FUNCTION public.generate_sif_2023(date, date);

CREATE OR REPLACE FUNCTION public.generate_sif_2023(
    IN from_date date,
    IN to_date date)
  RETURNS TABLE(acctno_ character varying, loancode_ character, loanser_ character, name_ character varying, trans_date_ date, service_fee_ numeric, service_fee_adj_ numeric, interest_ numeric, interest_adj_ numeric, fines_ numeric, fines_adj_ numeric) AS
$BODY$
   
DECLARE

BEGIN

	RETURN QUERY SELECT 	tbl.acctno,
				tbl.loancode,
				tbl.loanser,
				tbl.name::varchar,
				tbl.trans_date,
				SUM(tbl.service_fee) AS service_fee,
				SUM(tbl.service_fee_adj) AS service_fee_adj,
				SUM(tbl.interest) AS interest,
				SUM(tbl.interest_adj) AS interest_adj,
				SUM(tbl.fines) AS fines,
				SUM(tbl.fines_adj) AS fines_adj
			FROM (
				SELECT a.acctno,
					a.loancode,
					a.loanser,
					CONCAT(TRIM(c.lname),', ',TRIM(c.fname),' ',LEFT(TRIM(c.mname),1),'.') AS name,
					trans_date,
					(CASE LEFT(trans_type,1)
					WHEN '0' THEN (CASE SUBSTR(trans_type,2,1)
							WHEN 'S' THEN amount::numeric(12,2)
							ELSE 0 END)
					ELSE 0 END) AS service_fee,
					(CASE LEFT(trans_type,1)
					WHEN '1' THEN (CASE SUBSTR(trans_type,2,1)
							WHEN 'S' THEN amount::numeric(12,2)
							ELSE 0 END)
					ELSE 0 END) AS service_fee_adj,
					(CASE LEFT(trans_type,1)
					WHEN '0' THEN (CASE SUBSTR(trans_type,2,1)
							WHEN 'I' THEN amount::numeric(12,2)
							ELSE 0 END)
					ELSE 0 END) AS interest,
					(CASE LEFT(trans_type,1)
					WHEN '1' THEN (CASE SUBSTR(trans_type,2,1)
							WHEN 'I' THEN amount::numeric(12,2)
							ELSE 0 END)
					ELSE 0 END) AS interest_adj,	
					(CASE LEFT(trans_type,1)
					WHEN '0' THEN (CASE SUBSTR(trans_type,2,1)
							WHEN 'F' THEN amount::numeric(12,2)
							ELSE 0 END)
					ELSE 0 END) AS fines,
					(CASE LEFT(trans_type,1)
					WHEN '1' THEN (CASE SUBSTR(trans_type,2,1)
							WHEN 'F' THEN amount::numeric(12,2)
							ELSE 0 END)
					ELSE 0 END) AS fines_adj
				FROM loan_sl a
				
				JOIN sl_df b ON TRIM(a.trans_no) = TRIM(b.trans_no)
				JOIN mmaster c ON a.acctno = c.acctno
				WHERE trans_date::date BETWEEN from_date AND to_date
				AND SUBSTR(trans_type,2,1) IN ('S','I','F')
				--AND CONCAT(a.acctno,a.loancode,a.loanser) = '70-06029YA'
				ORDER BY a.trans_no
			)tbl
			GROUP BY tbl.acctno, tbl.name, tbl.trans_date, tbl.loancode, tbl.loanser
			ORDER BY tbl.trans_date, tbl.acctno, tbl.loancode, tbl.loanser;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION public.generate_sif_2023(date, date)
  OWNER TO postgres;
