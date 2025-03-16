class UTPlusGameEventChain extends Object;

var UTPlusGameEvent Newest;

function Play(float T) {
	local UTPlusGameEvent E;

	E = new class'UTPlusGameEvent';
	E.Play(T);
	E.Next = Newest;
	Newest = E;
}

function Pause(float T) {
	local UTPlusGameEvent E;

	E = new class'UTPlusGameEvent';
	E.Pause(T);
	E.Next = Newest;
	Newest = E;
}

function bool IsPlaying() {
	return Newest.IsPlaying();
}

function bool IsPaused() {
	return Newest.IsPaused();
}

function float RealPlayTime(float TimeStamp, float DeltaTime) {
	local float RealTime;
	local float SegmentTime;
	local UTPlusGameEvent E;

	for(E = Newest; DeltaTime > 0; E = E.Next) {
		SegmentTime = FMin(DeltaTime, (TimeStamp - E.TimeStamp));
		if (E.IsPlaying()) {
			RealTime += SegmentTime;
		}
		DeltaTime -= SegmentTime;
	}

	return RealTime;
}
