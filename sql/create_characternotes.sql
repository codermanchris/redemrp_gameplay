CREATE TABLE `characternotes` (
  `Id` int(11) NOT NULL AUTO_INCREMENT,
  `CharacterId` int(11) NOT NULL,
  `SheriffId` int(11) NOT NULL,
  `LocationId` int(11) NOT NULL,
  `Message` varchar(255) CHARACTER SET utf8 NOT NULL,
  `CreateDate` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`Id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
