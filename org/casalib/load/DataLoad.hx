﻿/*	CASA Lib for ActionScript 3.0	Copyright (c) 2009, Aaron Clinger & Contributors of CASA Lib	All rights reserved.		Redistribution and use in source and binary forms, with or without	modification, are permitted provided that the following conditions are met:		- Redistributions of source code must retain the above copyright notice,	  this list of conditions and the following disclaimer.		- Redistributions in binary form must reproduce the above copyright notice,	  this list of conditions and the following disclaimer in the documentation	  and/or other materials provided with the distribution.		- Neither the name of the CASA Lib nor the names of its contributors	  may be used to endorse or promote products derived from this software	  without specific prior written permission.		THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"	AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE	IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE	ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE	LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR	CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF	SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS	INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN	CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)	ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE	POSSIBILITY OF SUCH DAMAGE.*/package org.casalib.load; 	import flash.events.IEventDispatcher;	import flash.events.HTTPStatusEvent;	import flash.events.SecurityErrorEvent;	import flash.net.URLLoader;	import flash.net.URLLoaderDataFormat;	import flash.net.URLVariables;	import org.casalib.load.LoadItem;	import flash.utils.ByteArray;		/*[Event(name="httpStatus", type="flash.events.HTTPStatusEvent")]*/	/*[Event(name="securityError", type="flash.events.SecurityErrorEvent")]*/		/**		Provides an easy and standardized way to load data.				@author Aaron Clinger		@version 09/06/09		@example			<code>				package {					import org.casalib.display.CasaMovieClip;					import org.casalib.events.LoadEvent;					import org.casalib.load.DataLoad;															public class MyExample extends CasaMovieClip {						protected var _dataLoad:DataLoad;																		public function MyExample() {							super();														this._dataLoad = new DataLoad("data.xml");							this._dataLoad.addEventListener(LoadEvent.COMPLETE, this._onComplete);							this._dataLoad.start();						}												protected function _onComplete(e:LoadEvent):void {							trace(this._dataLoad.dataAsXml.toXMLString());						}					}				}			</code>	*/	class DataLoad extends LoadItem {						/**			Creates and defines a DataLoad.						@param request: A <code>String</code> or an <code>URLRequest</code> reference to the file you wish to load.			@param dataFormat: Sets whether the data is received as as text, raw binary data or URL-encoded variables; defaults to text.		*/								public var data(getData, null) : Dynamic ;						public var dataAsByteArray(getDataAsByteArray, null) : ByteArray ;						public var dataAsString(getDataAsString, null) : String ;						public var dataAsUrlVariables(getDataAsUrlVariables, null) : URLVariables ;						public var dataAsXml(getDataAsXml, null) : XML ;						public var dataFormat(getDataFormat, null) : String ;						public var urlLoader(getUrlLoader, null) : URLLoader ;						/**			Creates and defines a DataLoad.						@param request: A <code>String</code> or an <code>URLRequest</code> reference to the file you wish to load.			@param dataFormat: Sets whether the data is received as as text, raw binary data or URL-encoded variables; defaults to text.		*/		public function new(request:Dynamic, ?dataFormat:String = URLLoaderDataFormat.TEXT) {			var urlLoader:URLLoader = new URLLoader();			urlLoader.dataFormat    = dataFormat;						super(urlLoader, request);						this._initListeners(this._loadItem);		}				/**			The URLLoader being used to download the data.		*/		public function getUrlLoader():URLLoader {			return cast( this._loadItem, URLLoader);		}				/**			The data received from the DataLoad. Available after load is complete.						@throws Error if method is called before the file has loaded.		*/		public function getData():Dynamic {			if (!this.loaded)				throw new Error('Cannot access an external data until the file has loaded.');						return this._loadItem.data;		}				/**			The data type that DataLoad is receiving.		*/		public function getDataFormat():String {			return this._loadItem.dataFormat;		}				/**			The data received from the DataLoad data typed as String. Available after load is complete.						@throws Error if method is called before the file has loaded.			@throws Error if method cannot convert data to a String.		*/		public function getDataAsString():String {			if (this.dataFormat == URLLoaderDataFormat.BINARY)				throw new Error('Cannot convert data to a String.');						if (this.dataFormat == URLLoaderDataFormat.VARIABLES)				return this.data.toString();						return this.data;		}				/**			The data received from the DataLoad data typed as XML. Available after load is complete.						@throws Error if method is called before the file has loaded.			@throws Error if method cannot convert data to XML.		*/		public function getDataAsXml():XML {			if (this.dataFormat != URLLoaderDataFormat.TEXT)				throw new Error('Cannot convert data to XML.');						return new XML(this.data);		}				/**			The data received from the DataLoad data typed as URLVariables. Available after load is complete.						@throws Error if method is called before the file has loaded.			@throws Error if method cannot convert data to URLVariables.		*/		public function getDataAsUrlVariables():URLVariables {			if (this.dataFormat == URLLoaderDataFormat.BINARY)				throw new Error('Cannot convert data to URLVariables.');						if (this.dataFormat == URLLoaderDataFormat.TEXT)				return new URLVariables(this.data);						return this.data;		}				/**			The data received from the DataLoad data typed as ByteArray. Available after load is complete.						@throws Error if method is called before the file has loaded.			@throws Error if method cannot convert data to a ByteArray.		*/		public function getDataAsByteArray():ByteArray {			if (this.dataFormat != URLLoaderDataFormat.BINARY)				throw new Error('Cannot convert data to a ByteArray.');						return this.data;		}				public override function destroy():Void {			this._dispatcher.removeEventListener(HTTPStatusEvent.HTTP_STATUS, this._onHttpStatus);			this._dispatcher.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, this.dispatchEvent);						super.destroy();		}				/**			@sends HTTPStatusEvent#HTTP_STATUS - Dispatched if class is able to detect and return the status code for the request.			@sends SecurityErrorEvent#SECURITY_ERROR - Dispatched if load is outside the security sandbox.		*/		override function _initListeners(dispatcher:IEventDispatcher):Void {			super._initListeners(dispatcher);						this._dispatcher.addEventListener(HTTPStatusEvent.HTTP_STATUS, this._onHttpStatus, false, 0, true);			this._dispatcher.addEventListener(SecurityErrorEvent.SECURITY_ERROR, this.dispatchEvent, false, 0, true);		}	}