class MutAutoScreenshot extends HUDMutator;
// Description="Automatically takes a screenshot at the end of a match"

auto state WaitForGameEnd {
	simulated event Tick(float DeltaTime) {
		super.Tick(DeltaTime);

		if (LocalPlayer == none)
			return;

		if (LocalPlayer.GameReplicationInfo != none && LocalPlayer.GameReplicationInfo.GameEndedComments != "") {
			GoToState('DoScreenshot');
		}
	}
}

state DoScreenshot {
	simulated event BeginState() {
		LocalPlayer.bShowScores = true;
	}

	simulated event Tick(float DeltaTime) {
		super.Tick(DeltaTime);

		LocalPlayer.ClientMessage(LocalPlayer.ConsoleCommand("shot"), 'MutAutoScreenshot');

		GoToState('Done');
	}
}

state Done {
	simulated event BeginState() {
		Disable('Tick');
		Disable('PostRender');
	}
}
