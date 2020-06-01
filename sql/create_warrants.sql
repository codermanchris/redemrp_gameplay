CREATE TABLE `warrants` (
  `Id` int(11) NOT NULL AUTO_INCREMENT,
  `SheriffId` int(11) NOT NULL,
  `Reason` varchar(512) CHARACTER SET utf8 NOT NULL,
  `CreateDate` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`Id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
