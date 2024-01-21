Diccionario de datos
Privada (SYS)
X$* => (G)V$*
*$  => USER/ALL/DBA*
Publica
USER/ALL/DBA*
--
----------------------------------------------------------------------------------------------
--SQL que se utilizan para obtener información sobre las restricciones y los índices.--
--
--Este comando selecciona el nombre de las restricciones del usuario donde el tipo de restricción es ‘P’ (Primary Key) o ‘U’ (Unique).
SELECT CONSTRAINT_NAME FROM USER_CONSTRAINTS WHERE CONSTRAINT_TYPE IN ('P','U')
--selecciona todos los campos de los índices del usuario donde el nombre del índice está en la lista de nombres de restricciones que 
--son Primary Key o Unique. En otras palabras, está buscando todos los índices que están asociados con una Primary Key o una restricción Unique.
SELECT * FROM USER_INDEXES
WHERE INDEX_NAME IN (SELECT CONSTRAINT_NAME FROM USER_CONSTRAINTS WHERE CONSTRAINT_TYPE IN ('P','U'))
--selecciona el nombre del segmento y el tamaño en bytes de los segmentos del usuario donde el nombre del segmento está en la lista de nombres
-- de restricciones que son Primary Key o Unique. Los segmentos en Oracle son un conjunto de estructuras que contienen los datos de la base de datos. 
--En este caso, está buscando el tamaño en bytes de los segmentos que están asociados con una Primary Key o una restricción Unique.
SELECT SEGMENT_NAME, BYTES FROM USER_SEGMENTS
WHERE SEGMENT_NAME IN (SELECT CONSTRAINT_NAME FROM USER_CONSTRAINTS WHERE CONSTRAINT_TYPE IN ('P','U'))
----------------------------------------------------------------------------------------------
--
CREATE TABLE CONS_IND_SEGS --Crea una tabla
(CONS_NAME VARCHAR2(40) --Tipo de dato que puede contener hasta 40 caracteres
,IND_FLAG NUMBER		--Tipo de dato Number
,SEG_FLAG NUMBER		--Tipo de dato Number
,SIZE_SEGS NUMBER);		--Tipo de dato Number
--
--Un cursor variable temporal que se utiliza para almacenar los resultados de una consulta SQL para su posterior procesamiento
--selecciona el nombre de las restricciones (CONSTRAINT_NAME) de la tabla USER_CONSTRAINTS donde el tipo de restricción (CONSTRAINT_TYPE) es ‘P’
-- (Primary Key) o ‘U’ (Unique). El resultado de esta consulta se almacena en el cursor C_CONS
DECLARE 
CURSOR C_CONS IS 
SELECT CONSTRAINT_NAME CONSNAME 
FROM USER_CONSTRAINTS WHERE CONSTRAINT_TYPE IN ('P','U');
--
--
MI_CONS  	CONS_IND_SEGS.CONS_NAME%TYPE:='NULO'; --Declara una variable MI_CONS del mismo tipo que la columna CONS_NAME en la tabla CONS_IND_SEGS e inicializa su valor a ‘NULO’.
MI_IND_FLAG	CONS_IND_SEGS.IND_FLAG%TYPE:= 0; -- Declara una variable MI_IND_FLAG del mismo tipo que la columna IND_FLAG en la tabla CONS_IND_SEGS e inicializa su valor a 0.
MI_SEG_FLAG CONS_IND_SEGS.SEG_FLAG%TYPE:= 0; -- Declara una variable MI_SEG_FLAG del mismo tipo que la columna SEG_FLAG en la tabla CONS_IND_SEGS e inicializa su valor a 0.
MI_SIZE		CONS_IND_SEGS.SIZE_SEGS%TYPE:= 0;--Declara una variable MI_SIZE del mismo tipo que la columna SIZE_SEGS en la tabla CONS_IND_SEGS e inicializa su valor a 0.
--
--seleccionar el valor 1 de la tabla USER_INDEXES donde el nombre del índice (INDEX_NAME) es igual a CNAME, que es el parámetro de entrada de la función. 
--Si encuentra un índice con ese nombre, asigna el valor 1 a MI_RETORNO.
--
--Si no encuentra un índice con ese nombre (lo que provocaría un error), captura la excepción y asigna el valor 0 a MI_RETORNO. Esto se hace en la cláusula
-- EXCEPTION WHEN OTHERS THEN MI_RETORNO := 0;.
--
--Finalmente, la función devuelve el valor de MI_RETORNO.
FUNCTION TIENE_INDICE(CNAME CONS_IND_SEGS.CONS_NAME%TYPE) RETURN NUMBER
IS
MI_RETORNO NUMBER:=0;
BEGIN
	BEGIN
		SELECT 1 INTO MI_RETORNO
		FROM USER_INDEXES
		WHERE INDEX_NAME= CNAME;
	EXCEPTION
		WHEN OTHERS THEN MI_RETORNO := 0;
	END;
	RETURN MI_RETORNO;
END;
--
-- toma un parámetro CNAME del mismo tipo que la columna CONS_NAME en la tabla CONS_IND_SEGS. La función devuelve un número.
--seleccionar el valor de la columna BYTES de la tabla USER_SEGMENTS donde el nombre del segmento (SEGMENT_NAME) es igual a CNAME, que es el parámetro de entrada de la función. 
--Si encuentra un segmento con ese nombre, asigna el valor de BYTES a MI_RETORNO.
--
--Si no encuentra un segmento con ese nombre (lo que provocaría un error), captura la excepción y asigna el valor 0 a MI_RETORNO. Esto se hace en la cláusula EXCEPTION WHEN OTHERS THEN MI_RETORNO := 0;.
--
FUNCTION TIENE_SEGMENTO(CNAME CONS_IND_SEGS.CONS_NAME%TYPE) RETURN NUMBER
IS
MI_RETORNO NUMBER:=0;
BEGIN
	BEGIN
		SELECT BYTES INTO MI_RETORNO
		FROM USER_SEGMENTS
		WHERE SEGMENT_NAME= CNAME;
	EXCEPTION
		WHEN OTHERS THEN MI_RETORNO := 0;
	END;
	RETURN MI_RETORNO;
END;
--
/***************************** SECCION EJECUTABLE ***********************/
BEGIN
	--
	FOR REC_CONS IN C_CONS LOOP
		--
		MI_CONS := REC_CONS.CONSNAME; 			--: Asigna el valor del campo CONSNAME del registro actual del cursor C_CONS a la variable MI_CONS
        MI_IND_FLAG:=TIENE_INDICE(MI_CONS);		--Llama a la función TIENE_INDICE con MI_CONS como parámetro y asigna el resultado a la variable MI_IND_FLAG.
        MI_SIZE:= TIENE_SEGMENTO(MI_CONS);		-- llama a la función TIENE_SEGMENTO y asigna el resultado a la variable MI_SIZE
		IF MI_SIZE = 0 THEN MI_SEG_FLAG := 0;	--Este es un bloque de control de flujo que asigna un valor a la variable MI_SEG_FLAG basado en si MI_SIZE es igual a 0 o no.
		ELSE MI_SEG_FLAG := 1;
		END IF;
		--Este comando inserta un nuevo registro en la tabla CONS_IND_SEGS con los valores de las variables MI_CONS, MI_IND_FLAG, MI_SEG_FLAG, y MI_SIZE.		
		INSERT INTO CONS_IND_SEGS(CONS_NAME ,IND_FLAG ,SEG_FLAG ,SIZE_SEGS) 
		VALUES (MI_CONS,MI_IND_FLAG,MI_SEG_FLAG,MI_SIZE);
		--
	END LOOP
	COMMIT;
	--El bucle continúa hasta que se han procesado todos los registros en el cursor C_CONS. Después de que el bucle ha terminado, se ejecuta el comando COMMIT; 
	--para guardar los cambios en la base de datos.
END;
/