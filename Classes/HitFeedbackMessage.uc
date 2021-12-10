class HitFeedbackMessage extends LocalMessage;

static function ClientReceive( 
	PlayerPawn P,
	optional int Switch,
	optional PlayerReplicationInfo RelatedPRI_1, 
	optional PlayerReplicationInfo RelatedPRI_2,
	optional Object OptionalObject
) {
	P.ClientMessage("Dealt"@Switch@"Damage To"@RelatedPRI_1.PlayerName);
}
