--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*
Nombre de Reporte     : SCRIPT DE CREACION DE DIMENSIONES - BI SALUD Y NUTRICION INFANTIL
Descripcion           : Creacion de tablas de dimensiones y tablas temporales (TMP)
Base de Datos         : SQL SERVER
Requisito             : Ejecutar antes 0.-SCRIPT_FUNCIONES_LIMPIEZA.sql
*/
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/* 3.- TABLAS DE DIMENSIONES*/
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/* 3.1.- TABLA "DIM_ESTABLECIMIENTO"*/
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- DROP TABLE Dim_Establecimiento
CREATE TABLE Dim_Establecimiento (
    IdEstablecimiento       INT IDENTITY PRIMARY KEY,
    CodRenipress            VARCHAR(8) UNIQUE NOT NULL,
    NombreEESS              VARCHAR(150) NOT NULL,
    CategoriaEESS           VARCHAR(10),
    Diresa                  VARCHAR(100),
    Red                     VARCHAR(100),
    Microred                VARCHAR(100),
    Departamento            VARCHAR(50),
    Provincia               VARCHAR(80),
    Distrito                VARCHAR(80),
    FechaCarga              DATETIME DEFAULT(GETDATE()),
    FechaActualizacion      DATETIME
);

-- DROP TABLE TMP_Establecimiento
CREATE TABLE TMP_Establecimiento (
    IdEstablecimiento       INT IDENTITY PRIMARY KEY,
    CodRenipress            VARCHAR(8) NOT NULL,
    NombreEESS              VARCHAR(150) NOT NULL,
    CategoriaEESS           VARCHAR(10),
    Diresa                  VARCHAR(100),
    Red                     VARCHAR(100),
    Microred                VARCHAR(100),
    Departamento            VARCHAR(50),
    Provincia               VARCHAR(80),
    Distrito                VARCHAR(80),
    FechaCarga              DATETIME DEFAULT(GETDATE()),
    FechaActualizacion      DATETIME
);

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/* 3.2.- TABLA "DIM_TIEMPO"*/
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- DROP TABLE Dim_Tiempo
CREATE TABLE Dim_Tiempo (
    IdTiempo                INT IDENTITY PRIMARY KEY,
    Fecha                   INT UNIQUE NOT NULL,        -- AAAAMMDD
    Anio                    INT,
    Mes                     INT,
    NombreMes               VARCHAR(12),
    Trimestre               INT,
    Semestre                INT,
    PeriodoEstandarizado    VARCHAR(7),                 -- 2022-08
    FechaCarga              DATETIME DEFAULT(GETDATE()),
    FechaActualizacion      DATETIME
);

-- DROP TABLE TMP_Tiempo
CREATE TABLE TMP_Tiempo (
    IdTiempo                INT IDENTITY PRIMARY KEY,
    Fecha                   INT NOT NULL,
    Anio                    INT,
    Mes                     INT,
    NombreMes               VARCHAR(12),
    Trimestre               INT,
    Semestre                INT,
    PeriodoEstandarizado    VARCHAR(7),
    FechaCarga              DATETIME DEFAULT(GETDATE()),
    FechaActualizacion      DATETIME
);

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/* 3.3.- TABLA "DIM_GEOGRAFIA"*/
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- DROP TABLE Dim_Geografia
CREATE TABLE Dim_Geografia (
    IdGeografia             INT IDENTITY PRIMARY KEY,
    Ubigeo                  VARCHAR(6) UNIQUE NOT NULL,
    Departamento            VARCHAR(50),
    Provincia               VARCHAR(80),
    Distrito                VARCHAR(80),
    FechaCarga              DATETIME DEFAULT(GETDATE()),
    FechaActualizacion      DATETIME
);

-- DROP TABLE TMP_Geografia
CREATE TABLE TMP_Geografia (
    IdGeografia             INT IDENTITY PRIMARY KEY,
    Ubigeo                  VARCHAR(6) NOT NULL,
    Departamento            VARCHAR(50),
    Provincia               VARCHAR(80),
    Distrito                VARCHAR(80),
    FechaCarga              DATETIME DEFAULT(GETDATE()),
    FechaActualizacion      DATETIME
);

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/* 3.4.- TABLA "DIM_PACIENTE"*/
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- DROP TABLE Dim_Paciente
CREATE TABLE Dim_Paciente (
    IdPaciente              INT IDENTITY PRIMARY KEY,
    Sexo                    VARCHAR(1) NOT NULL,
    EdadMeses               INT NOT NULL,
    GrupoEtario             VARCHAR(15),
    FechaCarga              DATETIME DEFAULT(GETDATE()),
    FechaActualizacion      DATETIME,
    CONSTRAINT UQ_Dim_Paciente UNIQUE (Sexo, EdadMeses)
);

-- DROP TABLE TMP_Paciente
CREATE TABLE TMP_Paciente (
    IdPaciente              INT IDENTITY PRIMARY KEY,
    Sexo                    VARCHAR(1) NOT NULL,
    EdadMeses               INT NOT NULL,
    GrupoEtario             VARCHAR(15),
    FechaCarga              DATETIME DEFAULT(GETDATE()),
    FechaActualizacion      DATETIME
);

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/* 3.5.- TABLA "DIM_DIAGNOSTICO_ANEMIA"*/
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- DROP TABLE Dim_DiagnosticoAnemia
CREATE TABLE Dim_DiagnosticoAnemia (
    IdDiagnostico           INT IDENTITY PRIMARY KEY,
    Diagnostico             VARCHAR(30) UNIQUE NOT NULL,
    FechaCarga              DATETIME DEFAULT(GETDATE()),
    FechaActualizacion      DATETIME
);

-- DROP TABLE TMP_DiagnosticoAnemia
CREATE TABLE TMP_DiagnosticoAnemia (
    IdDiagnostico           INT IDENTITY PRIMARY KEY,
    Diagnostico             VARCHAR(30) NOT NULL,
    FechaCarga              DATETIME DEFAULT(GETDATE()),
    FechaActualizacion      DATETIME
);

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/* 3.6.- TABLA "DIM_PROGRAMA_SOCIAL"*/
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- DROP TABLE Dim_ProgramaSocial
CREATE TABLE Dim_ProgramaSocial (
    IdProgramaSocial        INT IDENTITY PRIMARY KEY,
    SIS                     VARCHAR(1) NOT NULL,        -- 1 si / 0 no / 9 sin dato
    Juntos                  VARCHAR(1) NOT NULL,
    QaliWarma               VARCHAR(1) NOT NULL,
    Pin                     VARCHAR(1) NOT NULL,
    FechaCarga              DATETIME DEFAULT(GETDATE()),
    FechaActualizacion      DATETIME,
    CONSTRAINT UQ_Dim_ProgramaSocial UNIQUE (SIS, Juntos, QaliWarma, Pin)
);

-- DROP TABLE TMP_ProgramaSocial
CREATE TABLE TMP_ProgramaSocial (
    IdProgramaSocial        INT IDENTITY PRIMARY KEY,
    SIS                     VARCHAR(1) NOT NULL,
    Juntos                  VARCHAR(1) NOT NULL,
    QaliWarma               VARCHAR(1) NOT NULL,
    Pin                     VARCHAR(1) NOT NULL,
    FechaCarga              DATETIME DEFAULT(GETDATE()),
    FechaActualizacion      DATETIME
);

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/* 3.7.- TABLA "DIM_ESTADO_NUTRICIONAL"*/
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- DROP TABLE Dim_EstadoNutricional
CREATE TABLE Dim_EstadoNutricional (
    IdEstadoNutricional     INT IDENTITY PRIMARY KEY,
    Categoria               VARCHAR(30) UNIQUE NOT NULL,
    FechaCarga              DATETIME DEFAULT(GETDATE()),
    FechaActualizacion      DATETIME
);

-- DROP TABLE TMP_EstadoNutricional
CREATE TABLE TMP_EstadoNutricional (
    IdEstadoNutricional     INT IDENTITY PRIMARY KEY,
    Categoria               VARCHAR(30) NOT NULL,
    FechaCarga              DATETIME DEFAULT(GETDATE()),
    FechaActualizacion      DATETIME
);
