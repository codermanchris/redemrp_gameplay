CREATE TABLE `bounties` (
  `Id` int(11) NOT NULL AUTO_INCREMENT,
  `CharacterId` int(11) NOT NULL,
  `SheriffId` int(11) NOT NULL,
  `TownId` int(11) NOT NULL,
  `Reason` varchar(512) CHARACTER SET utf8 NOT NULL,
  `CreateDate` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `Status` int(11) NOT NULL DEFAULT '0',
  `CompletedById` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`Id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
