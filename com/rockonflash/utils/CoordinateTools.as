class com.rockonflash.utils.CoordinateTools
{
	public static function localToLocal (from : MovieClip, to : MovieClip, origin : Object) : Object
	{
		var point : Object = origin == undefined ?
		{
			x : 0, y : 0
		} : origin;
		from.localToGlobal (point);
		to.globalToLocal (point);
		return point;
	}
}
