CREATE TABLE `arrests` (
  `Id` int(11) NOT NULL AUTO_INCREMENT,
  `CaseNumber` varchar(10) CHARACTER SET utf8 NOT NULL,
  `CharacterId` int(11) NOT NULL,
  `SheriffId` int(11) NOT NULL,
  `LocationOfCrime` varchar(100) CHARACTER SET utf8 DEFAULT NULL,
  `TimeOfCrime` varchar(100) CHARACTER SET utf8 DEFAULT NULL,
  `Reason` varchar(255) CHARACTER SET utf8 NOT NULL,
  `CreateDate` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`Id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=latin1;
