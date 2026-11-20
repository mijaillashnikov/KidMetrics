--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*
Nombre de Reporte     : SCRIPT DE CREACION DE LA TABLA DE HECHOS - BI SALUD Y NUTRICION INFANTIL
Descripcion           : Creacion de Fact_AtencionNutricional (grano: una atencion de un nino de 6 a 59 meses)
Base de Datos         : SQL SERVER
Requisito             : Ejecutar antes 1.-SCRIPT_CREACION_DIMENSIONES.sql
*/
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/* 4.- TABLA DE HECHOS "FACT_ATENCION_NUTRICIONAL"*/
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- DROP TABLE Fact_AtencionNutricional
CREATE TABLE Fact_AtencionNutricional (
    IdAtencion              BIGINT IDENTITY PRIMARY KEY,
    -- Llaves foraneas (Tiempo y Geografia son role-playing)
    IdTiempoAtencion        INT NOT NULL REFERENCES Dim_Tiempo (IdTiempo),
    IdTiempoHemoglobina     INT NOT NULL REFERENCES Dim_Tiempo (IdTiempo),
    IdEstablecimiento       INT NOT NULL REFERENCES Dim_Establecimiento (IdEstablecimiento),
    IdGeografiaEESS         INT NOT NULL REFERENCES Dim_Geografia (IdGeografia),
    IdGeografiaResidencia   INT NOT NULL REFERENCES Dim_Geografia (IdGeografia),
    IdPaciente              INT NOT NULL REFERENCES Dim_Paciente (IdPaciente),
    IdDiagnostico           INT NOT NULL REFERENCES Dim_DiagnosticoAnemia (IdDiagnostico),
    IdEstadoNutricional     INT NOT NULL REFERENCES Dim_EstadoNutricional (IdEstadoNutricional),
    IdProgramaSocial        INT NOT NULL REFERENCES Dim_ProgramaSocial (IdProgramaSocial),
    -- Trazabilidad
    IdRegistroOrigen        CHAR(64),                   -- hash SHA2_256 del registro de SA_PERU
    -- Medidas
    PesoKg                  DECIMAL(5,2),
    TallaCm                 DECIMAL(5,1),
    HemoglobinaObservada    DECIMAL(4,1),
    HemoglobinaCorregida    DECIMAL(5,2),
    -- Indicadores (1 = si / 0 = no)
    IndAnemia               TINYINT,
    IndCRED                 TINYINT,
    IndSuplementacion       TINYINT,
    IndConsejeria           TINYINT,
    IndSesionDemostrativa   TINYINT,
    IndTamizajeOportuno     TINYINT,
    IndDxInconsistente      TINYINT,
    CantidadAtenciones      INT DEFAULT(1),
    FechaCarga              DATETIME DEFAULT(GETDATE()),
    FechaActualizacion      DATETIME
);
