/********************************************
* zoom
* Version 0.5
* Copyright Roguish, December 29, 2006
* Contact: Elliot Mebane, info@roguish.com
* Do not use without prior written permission
*********************************************/
import mx.events.EventDispatcher;
import com.rockonflash.utils.CoordinateTools;

/* TODO
* Place mouse icon using attachMovie
* Handle mouse icon visibility based on movment and position
* Shift calculations to place image based on its center point so zoom factors less than 1 can be used
*/
class com.roguish.Zoom
{
	// X-pos of center of zoom region
	var _nXC : Number = null;
	// Y-pos of center of zoom region
	var _nYC : Number = null;
	// X-pos of top-left of zoom region
	var _nXO : Number = null;
	// Y-pos of top-left of zoom region
	var _nYO : Number = null;
	//var _nZO : Number = null;
	// Zoom Anchor - set when mouse clicked
	var _nZA : Number = null;
	// Zoom Factor
	var _nZF : Number = null;
	// Zoom Factor from previous scale
	var _nZFPrev : Number = null;
	// Zoom Factor Multiplier to gear mouse movements up/down
	// value 1 means that dragging the full width of the content will zoom the picture to 200%
	// increasing values add more zoom
	// this is primarily used if you don't want to scale the zoom exponentially (see _nZoomDeltaScaling below)
	var _nMouseFactor : Number = null;
	// X-pos of anchor point of Content
	var _nXA_Content : Number = null;
	// Y-pos of anchor point of Content
	var _nYA_Content : Number = null;
	// X-pos of anchor point of Display Region
	var _nXA_DisplayArea : Number = null;
	// Y-pos of anchor point of Display Region
	var _nYA_DisplayArea : Number = null;
	// width of display region
	var _nWidth : Number = null;
	// height of display region
	var _nHeight : Number = null;
	// half width of Display Region
	var _nHalfWidth : Number = null;
	// half height of Display Region
	var _nHalfHeight : Number = null;
	var _nContentHeight : Number = null;
	var _nContentWidth : Number = null;
	var _nContentHalfHeight : Number = null;
	var	_nContentHalfWidth : Number = null;
	var _nXDragO : Number = null;
	var _nYDragO : Number = null;
	var _nXDragMouseO : Number = null;
	var _nYDragMouseO : Number = null;
	var _nAlphaFade : Number = null;
	var _oMouse : Object = null;
	var _bZooming : Boolean = null;
	var _content : MovieClip = null;
	var _scope : MovieClip = null;
	var _mask : MovieClip = null;
	var _displayArea : Object = null;
	var _oController : Object = null;
	var _oKeyController : Object = null;
	var _mouse : MovieClip = null;
	// zoom minimum factor, defaults to 1
	var _nZoomFactorMin : Number = null;
	// zoom released at minimum value or not, defaults to false
	var _bReleaseZoomAtMinimum : Boolean = null;
	// the amount of left movement that must be exceeded to trigger the zoom release. Compensates for inadvertent "anticipation" mouse movement at start of zoom,
	// and also allows zooms down to near-minimum with zoom release enabled without the fear of hitting bottom and releasing the zoom.
	// number is made negative at config.
	var _nAnticipationBufferMovement : Number = null;
	// number representing full zoom factor.  used if an image starts smaller than the full mask size
	// the _nFullZoomFactor is calculated
	var _nFullZoomFactor : Number;
	// start with content filling mask or not. defaults to false.
	var _bStartContentAtFullZoomFactor : Boolean = null;
	// if content is smaller than mask, it may be preferable to center it when the zoom is applied. default is false.
	var _bStartCentered : Boolean = null;
	// scales the zoom factor as you zoom in.  very cool.  defaults to true.
	var _bZoomScaling : Boolean = null;
	// the factor for scaling more the farther you drag.  default = .01.  very sensitive
	var _nZoomDeltaScaling : Number = null;
	var _nZoomFactorMax : Number = null;
	//
	var _instance : Zoom = null;
	//
	public function Zoom (oData : Object)
	{
		/*
		*Before passing an object:
		* mcContent : MovieClip, mcScope : MovieClip, nMouseFactor : Number, nZoomPercentMin : Number, nZoomPercentMax : Number, bReleaseZoomAtMinimum : Boolean, nAnticipationBufferMovement : Number, aStroke : Array, useMask : Boolean, mcMask : MovieClip, useMouse : Boolean, mcMouseIcon : MovieClip, bZoomScaling : Boolean, nZoomDeltaScaling:Number)
		*
		* current method, pass object - easier instantiation:
		* oZoom.mcContent = mcActiveVP;
		oZoom.mcScope = null;
		oZoom.nMouseFactor = 5;
		oZoom.nZoomPercentMin = 100;
		oZoom.nZoomPercentMax = 500;
		oZoom.bReleaseZoomAtMinimum = false;
		oZoom.nAnticipationBufferMovement = 15;
		oZoom.aStroke = null;
		oZoom.useMask = null;
		oZoom.mcMask = mcVideoMask;
		oZoom.useMouse = true;
		oZoom.mcMouseIcon = mouseIcon;
		oZoom.bZoomScaling = true;
		oZoom.nZoomDeltaScaling = .02;
		oZoom.bStartContentAtFullZoomFactor = false;
		oZoom.bStartCentered = false;
		* */
		_instance = this;
		//
		mx.events.EventDispatcher.initialize (_instance);
		_content = oData.mcContent;
		if (oData.nMouseFactor == undefined)
		{
			_nMouseFactor = 1;
		} else
		{
			_nMouseFactor = oData.nMouseFactor;
		}
		if (oData.mcScope == undefined)
		{
			_scope = _content._parent;
		} else
		{
			_scope = oData.mcScope;
		}
		if (oData.nZoomPercentMin == undefined)
		{
			_nZoomFactorMin = 1;
		} else
		{
			_nZoomFactorMin = oData.nZoomPercentMin / 100;
		}
		if (oData.nZoomPercentMax == undefined)
		{
			_nZoomFactorMax = 30;
		} else
		{
			_nZoomFactorMax = oData.nZoomPercentMax / 100;
		}
		if (oData.bReleaseZoomAtMinimum == undefined)
		{
			_bReleaseZoomAtMinimum = false;
		} else
		{
			_bReleaseZoomAtMinimum = oData.bReleaseZoomAtMinimum;
		}
		if (oData.nAnticipationBufferMovement == undefined)
		{
			_nAnticipationBufferMovement = - 10;
		} else
		{
			_nAnticipationBufferMovement = - (Math.abs (oData.nAnticipationBufferMovement));
		}
		if (oData.bZoomScaling || oData.bZoomScaling == undefined)
		{
			_bZoomScaling = true;
		} else
		{
			_bZoomScaling = false;
		}
		if (oData.nZoomDeltaScaling == undefined)
		{
			_nZoomDeltaScaling =.01;
		} else
		{
			_nZoomDeltaScaling = oData.nZoomDeltaScaling;
			//trace("_nZoomDeltaScaling: " + _nZoomDeltaScaling);
			
		}
		if (oData.bStartContentAtFullZoomFactor == undefined )
		{
			_bStartContentAtFullZoomFactor = false;
		} else 
		{
			_bStartContentAtFullZoomFactor = oData.bStartContentAtFullZoomFactor;
		}
		if (oData.bStartCentered == undefined )
		{
			_bStartCentered = false;
		} else 
		{
			_bStartCentered = oData.bStartCentered;
		}
		var nStrokeWidth : Number;
		if (oData.useMask || oData.useMask == undefined)
		{
			if (oData.mcMask == undefined)
			{
				var mcMaskClip = _scope.createEmptyMovieClip ("mcMaskGenerated", _scope.getNextHighestDepth ());
				mcMaskClip._x = _content._x;
				mcMaskClip._y = _content._y;
				var oMaskBounds = _content.getBounds (_content);
				mcMaskClip.lineStyle (0, 0xFFFFFF, 100);
				mcMaskClip.beginFill (0xFFFFFF, 100);
				mcMaskClip.moveTo (0, 0);
				mcMaskClip.lineTo (oMaskBounds.xMax, 0);
				mcMaskClip.lineTo (oMaskBounds.xMax, oMaskBounds.yMax);
				mcMaskClip.lineTo (0, oMaskBounds.yMax);
				mcMaskClip.lineTo (0, 0);
				mcMaskClip.endFill ();
				_mask = mcMaskClip;
			} 
			else
			{
				_mask = oData.mcMask;
			}
			_content.setMask (_mask);
			_displayArea = _mask.getBounds (_scope);
		} else
		{
			_displayArea = _content.getBounds (_scope);
		}
		if (oData.aStroke != undefined)
		{
			var nStrokeWidth : Number = oData.aStroke [0];
			var nStrokeColor : Number = oData.aStroke [1];
			var mcStrokeClip = _scope.createEmptyMovieClip ("mcStrokeGenerated", _scope.getNextHighestDepth ());
			mcStrokeClip._x = _content._x;
			mcStrokeClip._y = _content._y;
			var oMaskBounds = _content.getBounds (_content);
			mcStrokeClip.lineStyle (nStrokeWidth, nStrokeColor, 100);
			mcStrokeClip.beginFill (0xFFFFFF, 0);
			mcStrokeClip.moveTo (0, 0);
			mcStrokeClip.lineTo (oMaskBounds.xMax, 0);
			mcStrokeClip.lineTo (oMaskBounds.xMax, oMaskBounds.yMax);
			mcStrokeClip.lineTo (0, oMaskBounds.yMax);
			mcStrokeClip.lineTo (0, 0);
			mcStrokeClip.endFill ();
		}
		_nWidth = _displayArea.xMax - _displayArea.xMin;
		_nHalfWidth = _nWidth / 2;
		_nHeight = _displayArea.yMax - _displayArea.yMin;
		_nHalfHeight = _nHeight / 2;
		if (oData.useMouse || oData.useMouse == undefined)
		{
			if (oData.mcMouseIcon == undefined)
			{
				oData.mcMouseIcon = _scope.attachMovie ("mouseIcon", "mcMouseIcon", _scope.getNextHighestDepth ());
			}
			_mouse = oData.mcMouseIcon;
			_mouse._visible = false;
			// if useMouse false or undefined, processor cycles aren't used watching the mouse to swap the graphics.
			mouseFollow ();
		}
		_oController = new Object ();
		_oController._instance = _instance;
		_oMouse = new Object ();
		_oKeyController = new Object ();
		_oKeyController._instance = _instance;
		//
		//
		/*
		_nXC = _mask._x + _mask._width / 2;
		_nYC = _mask._y + _mask._height / 2;
		_nXO = _mask._x;
		_nYO = _mask._y;
		*/
		_nXC = CoordinateTools.localToLocal (_mask, _scope,
		{
			x : _x, y : 0
		}).x + _mask._width / 2;
		_nYC = CoordinateTools.localToLocal (_mask, _scope,
		{
			x : 0, y : _y
		}).y + _mask._height / 2;
		_nXO = CoordinateTools.localToLocal (_mask, _scope,
		{
			x : _x, y : 0
		}).x;
		_nYO = CoordinateTools.localToLocal (_mask, _scope,
		{
			x : 0, y : _y
		}).y;
		//
		_nXA_Content = _nXC;
		_nYA_Content = _nYC;
		_nXA_DisplayArea = _nXC;
		_nYA_DisplayArea = _nYC;
		//
		_nContentHeight = oData.mcContent._height;
		_nContentWidth = oData.mcContent._width;
		_nContentHalfHeight = _nContentHeight / 2;
		_nContentHalfWidth = _nContentWidth / 2;
		var nStartZFHeight : Number = _nContentHeight / _nHeight;
		var nStartZFWidth : Number = _nContentWidth / _nWidth;
		var nStartZF : Number = Math.min (nStartZFHeight, nStartZFWidth);
		_nZF = _nZFPrev = nStartZF;
		//placeMC();
		//
		_nAlphaFade = 100;
		//
		_bZooming = false;
		//
		_oController.onMouseDown = function ()
		{
			// here, this == _oController
			// earlier we set _oController._instance = _instance
			var oScope = this._instance;
			// make sure we're hitting the mask area:
			if (oScope._mask.hitTest (_xmouse, _ymouse))
			{
				trace(oScope._mask._xmouse+" "+oScope._mask._ymouse);
				if (Key.isDown (Key.SPACE))
				{
					oScope._nXDragO = oScope._content._x;
					oScope._nYDragO = oScope._content._y;
					oScope._nXDragMouseO = oScope._scope._xmouse - oScope._displayArea.xMin;
					oScope._nYDragMouseO = oScope._scope._ymouse - oScope._displayArea.yMin;
					this.onMouseMove = oScope.fnMouseMoveDrag;
				} else
				{
					/*
					* oScope._nXA_Content = oScope._content._xmouse * oScope._nFullZoomFactor;
					trace("mouseDown, oScope._nFullZoomFactor: " + oScope._nFullZoomFactor);
					oScope._nYA_Content = oScope._content._ymouse * oScope._nFullZoomFactor;
					*/
					oScope._nXA_Content = oScope._content._xmouse ;
					oScope._nYA_Content = oScope._content._ymouse;
					oScope._nXA_DisplayArea = oScope._scope._xmouse - oScope._displayArea.xMin;
					oScope._nYA_DisplayArea = oScope._scope._ymouse - oScope._displayArea.yMin;
					oScope._nZA = oScope._mask._xmouse;
					oScope._nZFPrev = oScope._nZF;
					oScope._bZooming = true;
					this.onMouseMove = oScope.fnMouseMoveZoom;
				}
			}
		}
		_oController.onMouseUp = function ()
		{
			var oScope = this._instance;
			oScope._bZooming = false;
			delete oScope._oController.onMouseMove;
		};
		Mouse.addListener (_oController);
		//
		_oKeyController.onKeyDown = function ()
		{
			var oScope = this._instance;
			if (Key.getCode () == Key.SPACE && ! oScope._bZooming)
			{
				oScope._mouse.gotoAndStop ("hand");
			}
		};
		_oKeyController.onKeyUp = function ()
		{
			var oScope = this._instance;
			oScope._mouse.gotoAndStop ("mag");
		};
		Key.addListener (_oKeyController);
		//
		if (_nZF < _nZoomFactorMin)
		{
			_nFullZoomFactor = (_nZoomFactorMin / _nZF);
			// zoom to slightly larger than 100% so first zoom reacts properly.
			/*
			trace("_content._xscale: " + _content._xscale);
			_content._width*= _nFullZoomFactor;
			trace("_content._xscale: " + _content._xscale);
			_content._height*= _nFullZoomFactor;
			_nZF = _nZFPrev = _nZoomFactorMin;
			*/
			/*
			* trace ("_nZF: " + _nZF + ", _nZoomFactorMin: " + _nZoomFactorMin);
			// calculate the difference to zoom image to minimum size and zoom there
			_content._xscale = (_nZoomFactorMin / _nZF) * 100;
			_content._yscale = (_nZoomFactorMin / _nZF) * 100;
			
			*/
		} else
		{
			_nFullZoomFactor = _nZF;
			//trace("set _nFullZoomFactor: " + _nFullZoomFactor);
			
		}
		if (_bStartContentAtFullZoomFactor)
		{
			zoomToPercent (_nFullZoomFactor * 100.5, true);
		} else if (_bStartCentered)
		{
			zoomToPercent (null, true);
		}
		//placeMC ();
		
	}
	private function mouseFollow () : Void
	{
		trace ("mouseFollow()");
		// TODO: Mouse hides only when over content
		_oMouse = new Object ();
		_oMouse.thisMouse = _mouse;
		_oMouse._mask = _mask;
		_oMouse.onMouseMove = function ()
		{
			if (_mask.hitTest (_xmouse, _ymouse))
			{
				Mouse.hide ();
				this.thisMouse._x = _xmouse;
				this.thisMouse._y = _ymouse;
				this.thisMouse._visible = true;
			} else
			{
				this.thisMouse._visible = false;
				Mouse.show ();
			}
		};
		Mouse.addListener (_oMouse);
	}
	private function placeMC () : Void
	{
		var nScale : Number = _nZF * 100;
		_content._xscale = _content._yscale = nScale;
		//trace ("nScale: " + nScale);
		//trace ("placeMC, _nXO: " + _nXO + ", _nZF: " + _nZF +", _nXA_DisplayArea: " + _nXA_DisplayArea + ", _nXA_Content: " + _nXA_Content);
		var nSetX : Number = _nXO + _nXA_DisplayArea - (_nXA_Content * _nZF);
		//trace("nSetX: "+ nSetX);
		setX (nSetX);
		var nSetY : Number = _nYO + _nYA_DisplayArea - (_nYA_Content * _nZF);
		setY (nSetY);
	}
	private function setX (nX : Number)
	{
		//trace("nX: " + nX)
		if (nX >= _displayArea.xMin)
		{
			//trace ("setX status:  nX >= _displayArea.xMin,  _displayArea.xMin: " +  _displayArea.xMin);
			if (_nZF >= _nFullZoomFactor)
			{
				//	trace ("setX status:  _nZF >= _nFullZoomFactor");
				_content._x = _displayArea.xMin;
			} else
			{
				//trace ("setX status: _nZF<_nFullZoomFactor");
				// content is smaller than mask, so be sure it stays centered.
				// if it goes off center, scaling-up becomes a problem.
				//trace (_nWidth + " " + _content._width);
				_content._x = (_nXO + (_nWidth - _content._width) / 2);
			}
		} else
		{
			//trace ("setX status:  nX < _displayArea.xMin,  _displayArea.xMin: " +  _displayArea.xMin);
			var nXProposedRightEdge : Number = nX + (_content._width);
			if (nXProposedRightEdge < _displayArea.xMax)
			{
				//trace ("setX status: nXProposedRightEdge < _displayArea.xMax");
				_content._x = _displayArea.xMax - _content._width;
			} else
			{
				//trace ("setX status: nXProposedRightEdge >= _displayArea.xMax");
				_content._x = nX;
			}
		}
		//trace ("");
		
	}
	private function setY (nY : Number)
	{
		if (nY >= _displayArea.yMin)
		{
			if (_nZF >= _nFullZoomFactor)
			{
				_content._y = _displayArea.yMin;
			} else
			{
				//	trace ("setY status: _nZF<_nFullZoomFactor")
				//trace (_nYO + " " + _nHeight + " " + _content._height);
				_content._y = (_nYO + (_nHeight - _content._height) / 2);
			}
		} else
		{
			var nYProposedBottomEdge = nY + (_content._height);
			if (nYProposedBottomEdge < _displayArea.yMax)
			{
				_content._y = _displayArea.yMax - _content._height;
			} else
			{
				_content._y = nY;
			}
		}
		// TODO: needs optimization for broadcasting single event for x/y translation
		sendDrag (_content._x + "," + _content._y);
	}
	private function fnMouseMoveZoom ()
	{
		// cool.  this allows the zoom factor to be adjusted as you zoom in - exponentially-scaled zoom amount.
		// there must be cleaner math, though
		var nDelta : Number = _instance._mask._xmouse - _instance._nZA;
		if (_instance._bZoomScaling )
		{
			if (nDelta < 1)
			{
				var nSign : Number = - 1;
			} else
			{
				var nSign : Number = 1;
			}
			nDelta = Math.pow (nDelta, 2) * _instance._nZoomDeltaScaling * nSign;
		}
		var nZoomFactor : Number = _instance._nZFPrev + (nDelta / _instance._nWidth) * _instance._nMouseFactor ;
		if (nZoomFactor < _instance._nZoomFactorMin)
		{
			_instance._nZF = _instance._nZoomFactorMin;
		} else if (nZoomFactor > _instance._nZoomFactorMax)
		{
			_instance._nZF = _instance._nZoomFactorMax;
		} else
		{
			_instance._nZF = nZoomFactor;
		}
		//_instance._nZF = Math.min (Math.max (nZoomFactor, _instance._nZoomFactorMin) , _instance._nZoomFactorMax);
		_instance._nZF = Math.floor (_instance._nZF * 100) / 100;
		//trace ("_nMouseFactor: " + _instance._nMouseFactor + ", _instance._nZF: " + _instance._nZF + ", nZoomFactor: " + nZoomFactor);
		//trace ("_instance._nZF: " + _instance._nZF );
		// reset anchors
		if (_instance._nZF == _instance._nZoomFactorMin)
		{
			if (_instance._bReleaseZoomAtMinimum && nDelta < _instance._nAnticipationBufferMovement)
			{
				// remove zoom b/c we have zoomed down to orig value
				/* necessary?  was used when mousemove was automatically converted to a mousedrag at the bottom of the zoom scale
				_instance._nXDragO = _instance._content._x;
				_instance._nYDragO = _instance._content._y;
				_instance._nXDragMouseO = _instance._scope._xmouse - _instance._displayArea.xMin;
				_instance._nYDragMouseO = _instance._scope._ymouse - _instance._displayArea.yMin;
				*/
				delete _instance._oController.onMouseMove;
			}
			// was < 1
		}
		//
		if (_instance._nZF < _instance._nFullZoomFactor)
		{
			//trace ("zoom below _nFullZoomFactor");
			_instance._nXA_Content = _instance._nContentHalfWidth;
			_instance._nYA_Content = _instance._nContentHalfHeight;
			_instance._nXA_DisplayArea = _instance._nHalfWidth
			_instance._nYA_DisplayArea = _instance._nHalfHeight;
		}
		_instance.placeMC ();
		_instance.sendZoom (_instance._nZF.toString ());
		updateAfterEvent ();
	}
	private function fnMouseMoveDrag ()
	{
		if (_instance._nZF > 1)
		{
			var nNextX : Number = _instance._nXDragO + ((_instance._scope._xmouse - _instance._displayArea.xMin) - _instance._nXDragMouseO);
			var nNextY : Number = _instance._nYDragO + ((_instance._scope._ymouse - _instance._displayArea.yMin) - _instance._nYDragMouseO);
		}
		// x
		if (_instance._nZF == 1 && Math.abs (_instance._displayArea.xMin - nNextX) < 10)
		{
			_instance.setX (_instance._displayArea.xMin);
		} else
		{
			_instance.setX (nNextX);
		}
		// y
		if (_instance._nZF == 1 && Math.abs (_instance._displayArea.yMin - nNextY) < 10)
		{
			_instance.setY (_instance._displayArea.yMin);
			if (Math.abs (_instance._displayArea.xMin - nNextX) < 10)
			{
				// flash frame because both are set - visual flare
				_instance._scope.mcFrame.play ();
				delete _instance._oController.onMouseMove;
			}
		} else
		{
			_instance.setY (nNextY);
		}
		updateAfterEvent ();
	}
	// EventDispatcher methods
	function dispatchEvent ()
	{
	};
	function addEventListener ()
	{
	};
	function removeEventListener ()
	{
	};
	function sendZoom (sMessage : String) : Void
	{
		var oEvent : Object = {
		}
		oEvent.type = "receiveZoom";
		oEvent.sMessage = sMessage;
		dispatchEvent (oEvent);
	}
	function sendDrag (sMessage : String) : Void
	{
		var oEvent : Object = {
		}
		oEvent.type = "receiveDrag";
		oEvent.sMessage = sMessage;
		dispatchEvent (oEvent);
	}
	function zoomToPercent (nZoom : Number, bCenter : Boolean)
	{
		trace (nZoom);
		// not using 100, using _nZoomFactorMin
		if (nZoom == undefined || nZoom < _nZoomFactorMin)
		{
			nZoom = (_nZoomFactorMin * 100);
		}
		//_nXA_Content = _content._xmouse;
		//_nYA_Content = _content._ymouse;
		//_nXA_DisplayArea = _scope._xmouse - _displayArea.xMin;
		//_nYA_DisplayArea = _scope._ymouse - _displayArea.yMin;
		//_nZA = _scope._xmouse - _displayArea.xMin;
		//_nZFPrev = _nZF;
		_bZooming = true;
		//
		_nZF = nZoom / 100;
		// necessary?
		_nZFPrev = _nZF;
		if ( ! bCenter || bCenter == undefined)
		{
			var oCoords : Object = new Object ();
			oCoords.x = _nHalfWidth + _displayArea.xMin;
			oCoords.y = _nHalfHeight + _displayArea.yMin;
			var nPoint : Object = CoordinateTools.localToLocal (_scope, _content, oCoords);
			_nXA_Content = nPoint.x;
			_nYA_Content = nPoint.y;
			_nXA_DisplayArea = _nHalfWidth
			_nYA_DisplayArea = _nHalfHeight;
		} else
		{
			trace ("zoom to percent, bCenter == true: " + nZoom);
			_nXA_Content = _nHalfWidth;
			_nYA_Content = _nHalfHeight;
			_nXA_DisplayArea = _nHalfWidth
			_nYA_DisplayArea = _nHalfHeight;
		}
		placeMC ();
		sendZoom (_nZF.toString ());
		updateAfterEvent ();
	}
	//
	
}
