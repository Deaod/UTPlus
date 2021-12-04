class UTPlus extends Mutator
    config(UTPlus);

function ModifyLogin(
	out class<PlayerPawn> SpawnClass,
	out string Portal,
	out string Options
) {
	if (SpawnClass == none)
		return;

	if (ClassIsChildOf(SpawnClass, class'Spectator')) {
		SpawnClass = class'UTPlusSpectator';
	} else if (ClassIsChildOf(SpawnClass, class'TournamentPlayer')) {
		SpawnClass = class'UTPlusPlayer';
	}
}
