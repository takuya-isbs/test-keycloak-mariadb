DROP SCHEMA IF EXISTS demo;
CREATE SCHEMA demo;
USE demo;

DROP TABLE IF EXISTS users;

CREATE TABLE users
(
  id           INT(10) NOT NULL AUTO_INCREMENT,
  name     VARCHAR(40) NOT NULL,
  PRIMARY KEY (id)
);

INSERT INTO users (name) VALUES
    ("alice"),
    ("bob");
