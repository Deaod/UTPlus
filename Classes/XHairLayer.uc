class XHairLayer extends Object
	config perobjectconfig;

// 1x1 white texture as base for painting crosshairs
#exec Texture Import File=Textures\XHairBase.pcx Name=XHairBase Mips=Off

var() config bool   bUse;
var() config string Texture;
var() config int    OffsetX, OffsetY;
var() config float  ScaleX, ScaleY;
var() config color  Color;
var() config byte   Style;
var() config bool   bSmooth;

var Texture DrawTex;
var XHairLayer Next;

event Spawned() {
	if (bUse == false)
		return;

	if (Texture == "") {
		DrawTex = Texture'XHairBase';
	} else {
		DrawTex = Texture(DynamicLoadObject(Texture, class'Texture'));
	}
}

function Draw(Canvas C) {
	local float X, Y;
	local float XLength, YLength;

	X = C.ClipX / 2;
	Y = C.ClipY / 2;

	if (bUse == false)
		return;

	class'CanvasUtils'.static.SaveCanvas(C);

	XLength = ScaleX * DrawTex.USize;
	YLength = ScaleY * DrawTex.VSize;
	C.Style = Style;

	C.bNoSmooth = (bSmooth == false);
	C.SetPos(
		X - 0.5 * XLength + OffsetX,
		Y - 0.5 * YLength + OffsetY);
	C.DrawColor = Color;
	C.DrawTile(DrawTex, XLength, YLength, 0, 0, DrawTex.USize, DrawTex.VSize);

	class'CanvasUtils'.static.RestoreCanvas(C);
}

defaultproperties {
	bUse=False
	Texture=""
	OffsetX=0
	OffsetY=0
	ScaleX=1
	ScaleY=1
	Color=(R=255,G=255,B=255,A=255)
	Style=1
	bSmooth=False
}
