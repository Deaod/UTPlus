class XHairLayer extends Object
	config(XHairFactory) perobjectconfig;

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

function Draw(Canvas C, float Scale) {
	local float XLength, YLength;

	if (bUse == false)
		return;

	class'CanvasUtils'.static.SaveCanvas(C);

	XLength = Scale * ScaleX * DrawTex.USize;
	YLength = Scale * ScaleY * DrawTex.VSize;
	C.Style = Style;

	C.bNoSmooth = (bSmooth == false);
	C.SetPos(
		(C.ClipX - XLength) * 0.5 + Scale * OffsetX,
		(C.ClipY - YLength) * 0.5 + Scale * OffsetY);
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
