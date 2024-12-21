--ACTIVA ALMACENAMIENTO DE LOS MENSAJES DE SALIDAS 
SET SERVEROUTPUT ON;

--DESARROLLO REQUERIMIENTO 1 

--DECLARACION DE VARIABLES
DECLARE 
    
    v_sal_max employees.salary%TYPE;
    v_sal_prom employees.salary%TYPE;
    v_sal_min employees.salary%TYPE;
    v_sal_total employees.salary%TYPE;
    v_cant_emp NUMBER(3) := 0;
    
--INICIO DE EJECUTABLE DEL BLOQUE
BEGIN 
    
    SELECT MAX(salary), AVG(salary), MIN(salary), SUM(salary), COUNT(employee_id)
    INTO v_sal_max, v_sal_prom, v_sal_min, v_sal_total, v_cant_emp
    FROM employees
    WHERE salary > 8000; 
    
--IMPRESION DE RESULTADOS   
    DBMS_OUTPUT.PUT_LINE('INFORME DE LA EMPRESA                ' || TO_CHAR(SYSDATE, 'DD/MM/YY'));
    DBMS_OUTPUT.PUT_LINE('----------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('Salario Máximo          Salario Promedio         Salario Mínimo            Salario Total');
    DBMS_OUTPUT.PUT_LINE(
        TO_CHAR(v_sal_max, '$999,999')   ||'                 ' || 
        TO_CHAR(v_sal_prom, '$999,999')  ||'               ' || 
        TO_CHAR(v_sal_min, '$999,999')   ||'                 ' || 
        TO_CHAR(v_sal_total, '$999,999')
    );
    DBMS_OUTPUT.PUT_LINE('---------------------------------------------------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('Los valores calculados están efectuados sobre ' || v_cant_emp || ' empleados');
    
--FINALIZACION DEL BLOQUE    
END;



--DESARROLLO REQUERIMIENTO 2 

DECLARE
    v_total_dep NUMBER(3) := 0; 
    v_dep VARCHAR2(40); 

BEGIN
    
    SELECT department_name, COUNT(*) INTO v_dep, v_total_dep
    FROM employees e
    JOIN departments d ON e.department_id = d.department_id
    WHERE d.department_name = 'Sales'
    GROUP BY d.department_name;

    
    DBMS_OUTPUT.PUT_LINE('En el departamento ' || v_dep || ' trabajan ' || v_total_dep || ' empleados');
END;


--DESARROLLO REQUERIMIENTO 3 

CREATE TABLE PERSONAL_FALTANTE (
    ID_DEPARTAMENTO   NUMBER(4) PRIMARY KEY,
    TOTAL_EMPLEADOS   NUMBER(3),
    TOTAL_EMPLEADOS_FALTAN   NUMBER(3)
);

DECLARE 
    v_cant_depto_max NUMBER(2) := 0;
    v_max_empleados NUMBER(3);
    v_faltan_empleados NUMBER(3);
BEGIN
    -- Obtenemos el departamento con más empleados
    SELECT COUNT(employee_id)
    INTO v_cant_depto_max
    FROM departments d
    JOIN employees e ON d.department_id = e.department_id
    GROUP BY d.department_id
    HAVING COUNT(employee_id) = (
        SELECT MAX(COUNT(employee_id))
        FROM employees
        GROUP BY department_id
    );

    -- Obtenemos el total de empleados del departamento con más personal
    v_max_empleados := v_cant_depto_max;

    
    FOR dept IN (
        SELECT department_id, COUNT(employee_id) AS total_empleados
        FROM employees
        GROUP BY department_id
    ) LOOP
       
        IF dept.department_id IS NOT NULL THEN
           
            v_faltan_empleados := FLOOR(v_max_empleados * 0.5) - dept.total_empleados;

            INSERT INTO PERSONAL_FALTANTE (ID_DEPARTAMENTO, TOTAL_EMPLEADOS, TOTAL_EMPLEADOS_FALTAN)
            VALUES (dept.department_id, dept.total_empleados, 
                    CASE WHEN v_faltan_empleados > 0 THEN v_faltan_empleados ELSE 0 END);
        END IF;
    END LOOP;
END;

SELECT * FROM PERSONAL_FALTANTE;


--DESARROLLO REQUERIMIENTO 4 
CREATE TABLE ERRORES (
 SEC_ERROR NUMBER(5) PRIMARY KEY,
 NOMBRE_PROCESO VARCHAR2(80) NOT NULL,
 MENSAJE VARCHAR2(255) NOT NULL
);

DECLARE
    v_sec_error NUMBER;
    v_nombre_proceso VARCHAR2(80);
    v_mensaje VARCHAR2(255);
    v_department_id NUMBER;
    v_department_name VARCHAR2(100);
    v_manager_id NUMBER;
    v_location_id NUMBER;
BEGIN
    -- Prueba 1: Inserción válida
    v_department_id := 20; 
    v_department_name := 'Marketing'; 
    v_manager_id := NULL; 
    v_location_id := 1700;

    BEGIN
        -- Intentamos insertar un nuevo departamento
        INSERT INTO DEPARTMENTS (DEPARTMENT_ID, DEPARTMENT_NAME, MANAGER_ID, LOCATION_ID)
        VALUES (v_department_id, v_department_name, v_manager_id, v_location_id);

    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            -- Manejo de error: Clave duplicada
            SELECT NVL(MAX(SEC_ERROR), 0) + 1 INTO v_sec_error FROM ERRORES; 
            v_nombre_proceso := 'Bloque PL/SQL Inserta Departamento: Clave Duplicada';
            v_mensaje := 'Insertando un valor de Clave Primaria que ya existe: ' || v_department_id; 
            INSERT INTO ERRORES (SEC_ERROR, NOMBRE_PROCESO, MENSAJE)
            VALUES (v_sec_error, v_nombre_proceso, v_mensaje);

        WHEN OTHERS THEN
            -- Manejo de cualquier otro error
            SELECT NVL(MAX(SEC_ERROR), 0) + 1 INTO v_sec_error FROM ERRORES; 
            v_nombre_proceso := 'Bloque PL/SQL Inserta Departamento: Error General';
            v_mensaje := 'Error: ' || SQLERRM;
            INSERT INTO ERRORES (SEC_ERROR, NOMBRE_PROCESO, MENSAJE)
            VALUES (v_sec_error, v_nombre_proceso, v_mensaje);

    END;

    -- Prueba 2: Inserción con valores nulos
    v_department_id := 280; 
    v_department_name := NULL; 
    v_manager_id := NULL; 
    v_location_id := NULL;

    BEGIN
        -- Intentamos insertar un nuevo departamento con valores nulos
        INSERT INTO DEPARTMENTS (DEPARTMENT_ID, DEPARTMENT_NAME, MANAGER_ID, LOCATION_ID)
        VALUES (v_department_id, v_department_name, v_manager_id, v_location_id);

    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            -- Manejo de error: Clave duplicada
            SELECT NVL(MAX(SEC_ERROR), 0) + 1 INTO v_sec_error FROM ERRORES; 
            v_nombre_proceso := 'Bloque PL/SQL Inserta Departamento: Clave Duplicada';
            v_mensaje := 'Insertando un valor de Clave Primaria que ya existe: ' || v_department_id; 
            INSERT INTO ERRORES (SEC_ERROR, NOMBRE_PROCESO, MENSAJE)
            VALUES (v_sec_error, v_nombre_proceso, v_mensaje);

        WHEN OTHERS THEN
            -- Detectamos si el error es por valores nulos en campos obligatorios
            SELECT NVL(MAX(SEC_ERROR), 0) + 1 INTO v_sec_error FROM ERRORES; 
            v_nombre_proceso := 'Bloque PL/SQL Inserta Departamento: Error al insertar.';
            IF v_department_name IS NULL THEN
                v_mensaje := 'ORA-01400: cannot insert NULL into ("HR"."DEPARTMENTS"."DEPARTMENT_NAME")';
            ELSE
                v_mensaje := 'Error desconocido: ' || SQLERRM;
            END IF;
            INSERT INTO ERRORES (SEC_ERROR, NOMBRE_PROCESO, MENSAJE)
            VALUES (v_sec_error, v_nombre_proceso, v_mensaje);
    END;

    -- Realizamos un commit después de toda la transacción
    COMMIT;

END;


SELECT * FROM ERRORES; 

--DESARROLLO REQUERIMIENTO 5
DECLARE
    v_emp_id employees.employee_id%TYPE;  
    v_comision employees.commission_pct%TYPE;  

BEGIN
    
    FOR i IN 145 .. 179 LOOP
        
        SELECT employee_id, commission_pct
        INTO v_emp_id, v_comision
        FROM employees
        WHERE employee_id = i;

        
        IF v_comision > 0.3 THEN
            DBMS_OUTPUT.PUT_LINE('La comisión actual del empleado ' || v_emp_id || ' es de ' || v_comision || '. Es un buen porcentaje de comisión, no debe aumentar');
        ELSIF v_comision >= 0.2 AND v_comision <= 0.3 THEN
            DBMS_OUTPUT.PUT_LINE('La comisión actual del empleado ' || v_emp_id || ' es de ' || v_comision || '. Es un porcentaje de comisión normal. Se debe evaluar un reajuste');
        ELSE
            DBMS_OUTPUT.PUT_LINE('La comisión actual del empleado ' || v_emp_id || ' es de ' || v_comision || '. El porcentaje de comisión es bajo. Se debe evaluar un reajuste del 10%');
        END IF;
    END LOOP;

END;