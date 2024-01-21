DECLARE
/*
* Declaración de cursor explicito
*/

CURSOR C_EMP IS -- 107 REGISTROS
SELECT * 
FROM EMPLOYEES;

MI_ID              EMPLOYEES.EMPLOYEE_ID%TYPE:= 0; -- ID DEL EMPLEADO
MI_SALBASICO       CONCEPTS.CONCEPT_ID%TYPE:= 1; -- CODIGO DDEL CONCEPTO
MI_SALBASICO_VALOR PAYROLL.PYD_VALUE%TYPE:= 0; -- VALOR DEL CONCEPTO
MI_DIASLABORADOS   PARAMETROS2.VALOR%TYPE:= 0; -- DIAS LABORADOS
MIS_ANIOS  		   JOB_YEARS.YEARS%TYPE:= 0; -- ANIOS LABORADOS A LA FECHA
MI_ANTIGUEDAD      JOB_GRADES.HIGHEST_SAL%TYPE:= 0; -- VALOR PRIMA POR ANTIGUEDAD
MI_JEFATURA   	   JOB_GRADES.HIGHEST_SAL%TYPE:= 0; -- VALOR PRIMA POR JEFATURA
EL_SALARIO		   JOB_GRADES.HIGHEST_SAL%TYPE:= 0; -- EL SALARIO ASIGNADO
MI_SALUD           JOB_GRADES.HIGHEST_SAL%TYPE:= 0; -- APORTES POR Salud
MI_PENSION         JOB_GRADES.HIGHEST_SAL%TYPE:= 0; -- APORTES POR PENSION
MI_RETEFTE         JOB_GRADES.HIGHEST_SAL%TYPE:= 0; -- DESCUENTO POR RETEFTE
MI_PRIMA           JOB_GRADES.HIGHEST_SAL%TYPE:= 0; -- Valor prima por jefatura
MI_AA              JOB_GRADES.HIGHEST_SAL%TYPE:= 0; -- Auxilio de alimentación
MI_AT              JOB_GRADES.HIGHEST_SAL%TYPE:= 0; -- Auxilio ed trasporte
MI_DEVENGADO       JOB_GRADES.HIGHEST_SAL%TYPE:= 0; -- Total devengado 
MI_DEDUCIDO        JOB_GRADES.HIGHEST_SAL%TYPE:= 0; -- TOTAL DEDUCCIONES
MI_SALDO           JOB_GRADES.HIGHEST_SAL%TYPE:= 0; -- VALOR A RECIBIR
MI_FECHA_GENERA    ALL_USERS.CREATED%TYPE := sysdate;  -- Fecha de geenracion de la nomina
MI_USUARIO         ALL_USERS.USERNAME%TYPE := user; -- Nombre del usuario (esquema) de bases de datos
REC_NUM_DIAS		NUM_DAYS%ROWTYPE;-- Hereda estructura del registro en num days
REC_EMP 		   C_EMP%ROWTYPE; --Hereda estructura del registro definido es C_EMP
/*
* Función trae la edad 
*/

FUNCTION TRAER_ANIOS(PID NUMBER) RETURN NUMBER
IS
MI_RETORNO NUMBER:=0;
BEGIN
SELECT YEARS INTO MI_RETORNO
FROM JOB_YEARS
WHERE EMPLOYEE_ID= PID;
RETURN MI_RETORNO;
END;

/*
* Función trae los días 
*/

FUNCTION TRAER_DIAS(PID NUMBER) RETURN NUMBER
IS
MI_RETORNO NUMBER:=0;
BEGIN
SELECT NUM_DAYS INTO MI_RETORNO
FROM NUM_DAYS
WHERE EMPLOYEE_ID= PID;
RETURN MI_RETORNO;
END;

/*
* Función trae el salario
*/

FUNCTION TRAER_SALARIO(PID NUMBER) RETURN NUMBER
IS
MI_RETORNO NUMBER:=0;
BEGIN
SELECT SALARY INTO MI_RETORNO
FROM EMPLOYEES
WHERE EMPLOYEE_ID= PID;
RETURN MI_RETORNO;
END;


/*
* Función valida si es jefe o no
*/

FUNCTION SOY_JEFE(PID NUMBER) RETURN NUMBER
IS
MI_RETORNO NUMBER := 0;
BEGIN
BEGIN
SELECT 1 INTO MI_RETORNO
FROM EMPLOYEES E, JOBS J
WHERE E.EMPLOYEE_ID = PID
AND (E.JOB_ID LIKE '%MGR%'
OR E.JOB_ID LIKE '%MAN%')
AND E.JOB_ID = J.JOB_ID;
EXCEPTION
WHEN NO_DATA_FOUND THEN MI_RETORNO := 0;
END;
RETURN MI_RETORNO;
END;

--
-- SECCION EJECUTABLE
--
BEGIN
	--
	DELETE FROM PAYROLL;
	--
	FOR REC_ID IN C_EMP LOOP 
	MI_ID := REC_ID.EMPLOYEE_ID;
	DBMS_OUTPUT.PUT_LINE (LPAD(C_EMP%ROWCOUNT,5,'')||' '|| REC_ID.EMPLOYEE_ID || ' CON SALARIO ' ||
					REC_ID.SALARY || ' INGREO A LA EMPRESA EL ' ||
					REC_ID.HIRE_DATE || ' EN EL CARGO DE ' ||
					REC_ID.JOB_ID);
	
	--
	EL_SALARIO := TRAER_SALARIO(MI_ID);
	MI_DIASLABORADOS:= TRAER_DIAS(MI_ID);

	/*
	Salario Basico
	1 Salario Basico = (Salary/30)*NumDias
	*/

	SELECT (SALARY/TRAER_PARAMETRO('DM',1))*NUM_DAYS INTO MI_SALBASICO_VALOR
	FROM EMPLOYEES E, NUM_DAYS D
	WHERE E.EMPLOYEE_ID= D.EMPLOYEE_ID
	AND E.EMPLOYEE_ID = MI_ID;
	--
	INSERT INTO PAYROLL (EMPLOYEE_ID, PYD, PYD_VALUE)
	VALUES (MI_ID,MI_SALBASICO,MI_SALBASICO_VALOR);
	--

	/*
	Prima de antiguedad
	2 Prima de antiguedad= Si antiguedad entre 0 y 10  ==> 10% del codigo 1
	Si antiguedad entre 11 y 20 ==> 15% del codigo 1
	En los demas casos 20% del codigo 1
	*/

	MIS_ANIOS:= TRAER_ANIOS(MI_ID);
	IF MIS_ANIOS BETWEEN 0 AND 10 THEN MI_ANTIGUEDAD := MI_SALBASICO_VALOR*0.1;
	ELSIF MIS_ANIOS BETWEEN 11 AND 20 THEN MI_ANTIGUEDAD := MI_SALBASICO_VALOR*0.15;
	ELSE
	MI_ANTIGUEDAD := MI_SALBASICO_VALOR*0.20;
	END IF;
	--
	INSERT INTO PAYROLL (EMPLOYEE_ID, PYD, PYD_VALUE)
	VALUES (MI_ID,2,MI_ANTIGUEDAD);
	--

	/*
	Prima de servicios por jefatura
	3 Prima de servicios=  Si cargo es jefe, el 20% del codigo 1
	En los demas casos, no hay prima
	*/

	IF SOY_JEFE(MI_ID) = 1 THEN
	MI_PRIMA := MI_SALBASICO_VALOR*0.20;
	INSERT INTO PAYROLL (EMPLOYEE_ID, PYD, PYD_VALUE)
	VALUES (MI_ID,3,MI_PRIMA);
	--
	END IF;
		--
	/*
	Subsidio de alimentacion
	4 Subsidio de alimentacion= Si asignacion mensual < 3000 ==> SA= (100/30)* NumDias
	 En los demas caso, no hay auxilio

	*/

	IF EL_SALARIO < TRAER_PARAMETRO('AA',2) THEN
	MI_AA:=(TRAER_PARAMETRO('AA',1)/TRAER_PARAMETRO('DM',1))*MI_DIASLABORADOS;
			INSERT INTO PAYROLL (EMPLOYEE_ID, PYD, PYD_VALUE)
	VALUES (MI_ID,4,MI_AA);
	END IF;
	--

	/*
	5 Subsidio de transporte= Si asignacion mensual < 3000 ==> ST=(80/30)*NumDias
	En los demas casos no hay auxilio
	*/
		--
	IF EL_SALARIO < TRAER_PARAMETRO('AT',2) THEN
	MI_AT:=(TRAER_PARAMETRO('AT',1)/TRAER_PARAMETRO('DM',1))*MI_DIASLABORADOS;
			INSERT INTO PAYROLL (EMPLOYEE_ID, PYD, PYD_VALUE)
	VALUES (MI_ID,5,MI_AT);
	END IF;
		--
	/*
	10 Total devengado= Suma de los codigo 1-9
	*/

	MI_DEVENGADO := MI_AA+MI_AT+MI_SALBASICO_VALOR+MI_PRIMA+MI_ANTIGUEDAD;
	INSERT INTO PAYROLL (EMPLOYEE_ID, PYD, PYD_VALUE)
	VALUES (MI_ID,10,MI_DEVENGADO);
	--
	INSERT INTO genera_nomina VALUES (MI_FECHA_GENERA, MI_USUARIO);
	--

	/*
	11 Salud = 12% del codigo 1
	*/

	MI_SALUD := TRAER_PARAMETRO('SA',1)*MI_SALBASICO_VALOR;
	INSERT INTO PAYROLL (EMPLOYEE_ID, PYD, PYD_VALUE)
	VALUES (MI_ID, 11, MI_SALUD);

	/*
	12 Pension=16% del codigo 1
	*/

	MI_PENSION := TRAER_PARAMETRO('PE',1)*MI_SALBASICO_VALOR;
	INSERT INTO PAYROLL (EMPLOYEE_ID, PYD, PYD_VALUE)
	VALUES (MI_ID, 12, MI_PENSION);

	/*
	13  ReteFuente= Si asignacion mensual entre 0-1999, ==> 0% del codigo 1
	Si asignacion mensual entre 2000-4999 ==> 5% del codigo 1
	Si asignacion mensual entre 5000-8999 ==> 10% del codigo 1
	Los demas casos ==> 15% del codigo 1
	*/

	IF EL_SALARIO BETWEEN 0 AND 1999 THEN MI_RETEFTE := 0;
	ELSIF EL_SALARIO BETWEEN 2000 AND 4999 THEN MI_RETEFTE:= MI_SALBASICO_VALOR*0.05;
	ELSIF EL_SALARIO BETWEEN 5000 AND 8999 THEN MI_RETEFTE:= MI_SALBASICO_VALOR*0.1;
	ELSE MI_RETEFTE := MI_SALBASICO_VALOR*0.15;
	END IF;
	--
	IF MI_RETEFTE <> 0 THEN
	INSERT INTO PAYROLL (EMPLOYEE_ID, PYD, PYD_VALUE)
	VALUES (MI_ID, 13, MI_RETEFTE);
	END IF;

	/*
	*20 Total deducido= Suma de los codigo 11-19
	*/

	MI_DEDUCIDO := MI_RETEFTE+MI_PENSION+MI_SALUD;
	INSERT INTO PAYROLL (EMPLOYEE_ID, PYD, PYD_VALUE)
	VALUES (MI_ID, 20, MI_DEDUCIDO);

	/*
	30 Neto= Total devengado - total deducido
	*/
	MI_SALDO := MI_DEVENGADO - MI_DEDUCIDO;
	INSERT INTO PAYROLL (EMPLOYEE_ID, PYD, PYD_VALUE)
	VALUES (MI_ID, 30, MI_SALDO);
	--
	--

	END LOOP;
COMMIT;
END;
/