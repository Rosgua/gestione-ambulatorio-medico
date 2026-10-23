CREATE SCHEMA Ambulatorio_medico;
USE Ambulatorio_medico;

CREATE TABLE Paziente(
    pazienteID CHAR(9) NOT NULL,
    Nome VARCHAR(25) NOT NULL,
    Cognome VARCHAR(25) NOT NULL,
    Via VARCHAR(50),
    città_residenza VARCHAR(50),
    postalcode CHAR(9),
    gender VARCHAR(20),
    borndate DATE,
    città_nascita VARCHAR(50),
    email VARCHAR(50),
    phonenumber CHAR(10),
    PRIMARY KEY(pazienteID)
);

CREATE TABLE CartellaClinica(
    codice_cartella CHAR(9) NOT NULL,
    gruppo_sanguigno CHAR(3),
    pazienteID CHAR(9) NOT NULL,
    PRIMARY KEY(codice_cartella),
    FOREIGN KEY (pazienteID) REFERENCES Paziente(pazienteID)
);

CREATE TABLE Intervento(
    nome_intervento VARCHAR(50),
    data_intervento DATETIME,
    codice_cartella CHAR(9) NOT NULL,
    PRIMARY KEY (nome_intervento, data_intervento, codice_cartella),
    FOREIGN KEY (codice_cartella) REFERENCES CartellaClinica(codice_cartella)
);

CREATE TABLE Esame(
    nome_esame VARCHAR(50),
    data_esame DATETIME,
    codice_cartella CHAR(9) NOT NULL,
    PRIMARY KEY (nome_esame, data_esame, codice_cartella),
    FOREIGN KEY (codice_cartella) REFERENCES CartellaClinica(codice_cartella)
);

CREATE TABLE Malattia_Infettiva(
    nome_malattia VARCHAR(50),
    data  DATETIME,
    trattamento_effettuato TEXT,
    codice_cartella CHAR(9) NOT NULL,
    PRIMARY KEY(nome_malattia, data, codice_cartella),
    FOREIGN KEY (codice_cartella) REFERENCES CartellaClinica(codice_cartella)
);

CREATE TABLE Terapia(
    nome_terapia VARCHAR(50),
    data  DATETIME,
    codice_cartella CHAR(9) NOT NULL,
    PRIMARY KEY (nome_terapia, data, codice_cartella),
    FOREIGN KEY (codice_cartella) REFERENCES CartellaClinica(codice_cartella)
);

CREATE TABLE Allergia(
    nome_allergia VARCHAR(50),
    codice_cartella CHAR(9) NOT NULL,
    PRIMARY KEY (nome_allergia, codice_cartella),
    FOREIGN KEY (codice_cartella) REFERENCES CartellaClinica(codice_cartella)
);

CREATE TABLE Vaccino(
    nome_vaccino VARCHAR(50),
    data  DATETIME,
    codice_cartella CHAR(9) NOT NULL,
    PRIMARY KEY (nome_vaccino, data, codice_cartella),
    FOREIGN KEY (codice_cartella) REFERENCES CartellaClinica(codice_cartella)
);

CREATE TABLE PersonaleSanitario(
    personaleID INT NOT NULL AUTO_INCREMENT,
    PersonaleNome VARCHAR(25) NOT NULL,
    PersonaleCognome VARCHAR(25) NOT NULL,
    phonenumber CHAR(11),
    gender VARCHAR(20),
    email VARCHAR(50),
    tipologia ENUM('Infermiere', 'medico', 'specialista'),
    PRIMARY KEY(personaleID)
);

CREATE TABLE DisponibilitàPersonale(
    personaleID INT NOT NULL,
    giorno ENUM('Lunedi', 'Martedi', 'Mercoledi', 'Giovedi', 'Venerdi', 'Sabato', 'Domenica') NOT NULL,
    ora_inizio TIME NOT NULL,
    ora_fine TIME NOT NULL,
    PRIMARY KEY (personaleID, giorno, ora_inizio, ora_fine),
    CHECK (ora_inizio < ora_fine),
    FOREIGN KEY (personaleID) REFERENCES PersonaleSanitario(personaleID)
);

CREATE TABLE Specialista(
    specializzazione VARCHAR(50),
    personaleID INT,
    PRIMARY KEY (personaleID, specializzazione),
    FOREIGN KEY (personaleID) REFERENCES PersonaleSanitario(personaleID)
);

CREATE TABLE Infermiere(
    reparto VARCHAR(50),
    personaleID INT,
    PRIMARY KEY (personaleID, reparto),
    FOREIGN KEY (personaleID) REFERENCES PersonaleSanitario(personaleID)
);

CREATE TABLE Appuntamento(
    codiceAppuntamento INT NOT NULL AUTO_INCREMENT,
    giorno ENUM('Lunedi', 'Martedi', 'Mercoledi', 'Giovedi', 'Venerdi', 'Sabato') NOT NULL,
    ora_inizio TIME NOT NULL CHECK (ora_inizio BETWEEN '08:00:00' AND '19:00:00'),
    ora_fine TIME NOT NULL CHECK (ora_fine BETWEEN '08:00:00' AND '20:00:00'),
    dataApp DATE,
    tipoApp ENUM('Routine', 'Emergenza', 'Specialistica'),
    pazienteID CHAR(9) NOT NULL,
    personaleID INT NOT NULL,
    PRIMARY KEY (codiceAppuntamento),
    FOREIGN KEY (pazienteID) REFERENCES Paziente(pazienteID),
    FOREIGN KEY (personaleID) REFERENCES PersonaleSanitario(personaleID),
    CHECK (ora_inizio < ora_fine)
);

DELIMITER //
CREATE TRIGGER TR_tipologia
BEFORE INSERT ON Appuntamento
FOR EACH ROW
BEGIN
    IF NEW.tipoApp = 'Specialistica' THEN
        IF NOT EXISTS (
            SELECT 1
            FROM PersonaleSanitario
            WHERE personaleID = NEW.personaleID AND tipologia = 'specialista'
        ) THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Solo gli specialisti possono occuparsi delle visite specialistiche';
        END IF;
    ELSE
        IF NOT EXISTS (
            SELECT 1
            FROM PersonaleSanitario
            WHERE personaleID = NEW.personaleID AND tipologia = 'medico'
        ) THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Solo i medici possono occuparsi delle visite di routine o di emergenza';
        END IF;
    END IF;
END;
//
DELIMITER ;

DELIMITER //
CREATE TRIGGER TR_orario
BEFORE INSERT ON Appuntamento
FOR EACH ROW
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM DisponibilitàPersonale DP
        WHERE DP.personaleID = NEW.personaleID
          AND DP.giorno = NEW.giorno
          AND NEW.ora_inizio >= DP.ora_inizio
          AND NEW.ora_fine <= DP.ora_fine
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Appuntamento non rispetta gli orari di turno del personale sanitario';
    END IF;
END;
//
DELIMITER ;

CREATE TABLE Visita(
    codice_visita CHAR(6) NOT NULL,
    costo DECIMAL(5,2),
    sintomi_mostrati TEXT,
    parametri_vitali TEXT,
    trattamento_effettuato TEXT,
    diagnosi TEXT NOT NULL,
    codiceAppuntamento INT,
    PRIMARY KEY (codice_visita),
    FOREIGN KEY (codiceAppuntamento) REFERENCES Appuntamento(codiceAppuntamento)
);

CREATE TABLE Prescrizione(
    id_farmaco CHAR(6) NOT NULL,
    dosaggio_mg INT CHECK (dosaggio_mg > 0),
    durata_giorni INT,
    codice_visita CHAR(6),
    PRIMARY KEY (id_farmaco, codice_visita),
    FOREIGN KEY (codice_visita) REFERENCES Visita(codice_visita)
);

CREATE TABLE Inventario(
    id_farmaco CHAR(6) NOT NULL,
    nome_farmaco VARCHAR(50) NOT NULL,
    quantità_disp INT,
    descrizione TEXT,
    scadenza DATE NOT NULL,
    PRIMARY KEY (id_farmaco)
);

ALTER TABLE Prescrizione
ADD CONSTRAINT FOREIGN KEY (id_farmaco) REFERENCES Inventario(id_farmaco);

CREATE TABLE Feedback(
    id_feedback CHAR(6) NOT NULL,
    rating INT CHECK (rating <= 5),
    commento TEXT,
    codice_visita CHAR(6),
    PRIMARY KEY (id_feedback),
    FOREIGN KEY (codice_visita) REFERENCES Visita(codice_visita)
);


