CREATE TABLE `possemember` (
  `Id` int(11) NOT NULL AUTO_INCREMENT,
  `PosseId` int(11) NOT NULL,
  `CharacterId` int(11) NOT NULL,
  `Rank` smallint(6) NOT NULL,
  `JoinDate` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`Id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
