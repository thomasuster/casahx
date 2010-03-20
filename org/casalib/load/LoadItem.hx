/*
	CASA Lib for ActionScript 3.0
	Copyright (c) 2009, Aaron Clinger & Contributors of CASA Lib
	All rights reserved.
	
	Redistribution and use in source and binary forms, with or without
	modification, are permitted provided that the following conditions are met:
	
	- Redistributions of source code must retain the above copyright notice,
	  this list of conditions and the following disclaimer.
	
	- Redistributions in binary form must reproduce the above copyright notice,
	  this list of conditions and the following disclaimer in the documentation
	  and/or other materials provided with the distribution.
	
	- Neither the name of the CASA Lib nor the names of its contributors
	  may be used to endorse or promote products derived from this software
	  without specific prior written permission.
	
	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
	AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
	IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
	ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
	LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
	CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
	SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
	INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
	CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
	ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
	POSSIBILITY OF SUCH DAMAGE.
*/
package org.casalib.load; 
	import flash.events.Event;
	import flash.events.HTTPStatusEvent;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.net.URLRequest;
	import haxe.Timer;
	import org.casalib.core.UInt;
	import org.casalib.errors.ArguementTypeError;
	import org.casalib.events.LoadEvent;
	import org.casalib.events.RetryEvent;
	import org.casalib.math.Percent;
	import org.casalib.process.Process;
	import org.casalib.util.LoadUtil;
	import org.casalib.util.StringUtil;
	
	
	/*[Event(name="complete", type="org.casalib.events.LoadEvent")]*/
	/*[Event(name="ioError", type="flash.events.IOErrorEvent")]*/
	/*[Event(name="open", type="flash.events.Event")]*/
	/*[Event(name="progress", type="org.casalib.events.LoadEvent")]*/
	/*[Event(name="retry", type="org.casalib.events.RetryEvent")]*/
	/*[Event(name="start", type="org.casalib.events.LoadEvent")]*/
	/*[Event(name="stop", type="org.casalib.events.LoadEvent")]*/
	
	/**
		Base class used by load classes. LoadItem is not designed to be used on its own and needs to be extended to function.
		
		@author Aaron Clinger
		@version 05/30/09
	*/
	class LoadItem extends Process {
		
		public var Bps(getBps, null) : Int ;
		public var attempts(getAttempts, null) : UInt ;
		public var bytesLoaded(getBytesLoaded, null) : UInt ;
		public var bytesTotal(getBytesTotal, null) : Float ;
		public var httpStatus(getHttpStatus, null) : UInt ;
		public var latency(getLatency, null) : UInt ;
		public var loaded(getLoaded, null) : Bool ;
		public var loading(getLoading, null) : Bool ;
		public var preventCache(getPreventCache, setPreventCache) : Bool;
		public var progress(getProgress, null) : Percent ;
		public var retries(getRetries, setRetries) : UInt;
		public var time(getTime, null) : UInt ;
		public var url(getUrl, null) : String ;
		public var urlRequest(getUrlRequest, null) : URLRequest ;
		var _attempts:UInt;
		var _loaded:Bool;
		var _preventCache:Bool;
		var _retries:UInt;
		var _dispatcher:IEventDispatcher;
		var _Bps:Int;
		var _time:UInt;
		var _latency:UInt;
		var _httpStatus:UInt;
		var _loadItem:Dynamic;
		var _progress:Percent;
		var _request:URLRequest;
		var _startTime:Float;
		
		
		/**
			Defines the load object and file location.
			
			@param load: The load object.
			@param request: A String or an URLRequest reference to the file you wish to load.
			@throws ArguementTypeError if you pass a value type other than a String or URLRequest to parameter <code>request</code>.
		*/
		public function new(load:Dynamic, request:Dynamic) {
			super();
			
			this._createRequest(request);
			
			this._loadItem = load;
			this._retries  = 2;
			this._Bps      = -1;
			this._progress = new Percent();
		}
		
		/**
			Begins the loading process.
			
			@sends LoadEvent#START - Dispatched when a load is started.
		*/
		public override function start():Void {
			if (this.loading)
				return;
			
			super.start();
			
			this._loaded    = false;
			this._startTime = Timer.stamp();
			this._attempts  = 0;
			this._progress  = new Percent();
			this._Bps       = -1;
			this._time      = 0;
			
			if (this._preventCache) {
				var cache:String = 'casaCache=' + Std.int(1000 * Math.random());
				
				this._request.url = (this._request.url.indexOf('?') == -1) ? this._request.url + '?' + cache : this._request.url + '&' + cache;
			}
			
			this._load();
			
			this.dispatchEvent(this._createDefinedLoadEvent(LoadEvent.START));
		}
		
		/**
			Cancels the currently loading file from completing.
			
			@sends LoadEvent#STOP - Dispatched if the load is stopped during the loading process.
		*/
		public override function stop():Void {
			if (!this.loading || this.loaded)
				return;
			
			if (this.bytesTotal == this.bytesLoaded && this.bytesLoaded > 0)
				return;
			
			super.stop();
			
			this._loadItem.close();
			this.dispatchEvent(this._createDefinedLoadEvent(LoadEvent.STOP));
		}
		
		/**
			Specifies if a random value name/value pair should be appended to the query string to help prevent caching <code>true</code>, or not append <code>false</code>; defaults to <code>false</code>.
		*/
		public function getPreventCache():Bool{
			return this._preventCache;
		}
		
		public function setPreventCache(cache:Bool):Bool{
			this._preventCache = cache;
			return cache;
		}
		
		/**
			The total number of bytes of the requested file.
		*/
		public function getBytesTotal():Float {
			return (this._loadItem.bytesTotal == 0 && this.bytesLoaded != 0) ? Math.POSITIVE_INFINITY : this._loadItem.bytesTotal;
		}
		
		/**
			The number of bytes loaded of the requested file.
		*/
		public function getBytesLoaded():UInt {
			return this._loadItem.bytesLoaded;
		}
		
		/**
			The percent that the requested file has loaded.
		*/
		public function getProgress():Percent {
			return this._progress.clone();
		}
		
		/**
			The number of additional times the file has attempted to load after {@link #start start} was called.
		*/
		public function getAttempts():UInt {
			return this._attempts;
		}
		
		/**
			The number of additional load retries the class should attempt before failing; defaults to <code>2</code> additional retries / <code>3</code> total load attempts.
		*/
		public function getRetries():UInt{
			return this._retries;
		}
		
		public function setRetries(amount:UInt):UInt{
			this._retries = amount;
			return amount;
		}
		
		/**
			The URLRequest reference to the requested file.
		*/
		public function getUrlRequest():URLRequest {
			return this._request;
		}
		
		/**
			The URL of the requested file.
		*/
		public function getUrl():String {
			return this.urlRequest.url;
		}
		
		/**
			Determines if the requested file is loading <code>true</code>, or if it isn't currently loading <code>false</code>.
		*/
		public function getLoading():Bool {
			return this.running;
		}
		
		/**
			Determines if the requested file has loaded <code>true</code>, or hasn't finished loading <code>false</code>.
		*/
		public function getLoaded():Bool {
			return this._loaded;
		}
		
		/**
			The current download speed of the requested file in bytes per second.
		*/
		public function getBps():Int {
			return this._Bps;
		}
		
		/**
			The current time duration in milliseconds the load has taken.
		*/
		public function getTime():UInt {
			return this._time;
		}
		
		/**
			The time in milliseconds that the server took to respond.
		*/
		public function getLatency():UInt {
			return this._latency;
		}
		
		/**
			The HTTP status code returned by the server; or <code>0</code> if no status has/can been received or the load is a stream.
		*/
		public function getHttpStatus():UInt {
			return this._httpStatus;
		}
		
		public override function destroy():Void {
			this._dispatcher.removeEventListener(Event.COMPLETE, this._onComplete);
			this._dispatcher.removeEventListener(Event.OPEN, this._onOpen);
			this._dispatcher.removeEventListener(IOErrorEvent.IO_ERROR, this._onLoadError);
			this._dispatcher.removeEventListener(ProgressEvent.PROGRESS, this._onProgress);
			
			super.destroy();
		}
		
		function _initListeners(dispatcher:IEventDispatcher):Void {
			this._dispatcher = dispatcher;
			
			this._dispatcher.addEventListener(Event.COMPLETE, this._onComplete, false, 0, true);
			this._dispatcher.addEventListener(Event.OPEN, this._onOpen, false, 0, true);
			this._dispatcher.addEventListener(IOErrorEvent.IO_ERROR, this._onLoadError, false, 0, true);
			this._dispatcher.addEventListener(ProgressEvent.PROGRESS, this._onProgress, false, 0, true);
		}
		
		function _load():Void {
			this._loadItem.load(this._request);
		}
		
		function _createRequest(request:Dynamic):Void {
			if (Std.is( request, String)) {
				if (StringUtil.removeWhitespace(request) == '')
					throw 'Cannot load an empty reference/String';
				
				request = new URLRequest(request);
			} else if (!(Std.is( request, URLRequest)))
				throw new ArguementTypeError('request');
			
			this._request = request;
		}
		
		/**
			@sends RetryEvent#RETRY - Dispatched if the download attempt failed and the class is going to attempt to download the file again.
			@sends IOErrorEvent#IO_ERROR - Dispatched if requested file cannot be loaded and the download terminates.
		*/
		function _onLoadError(error:Event):Void {
			if (++this._attempts <= this._retries) {
				var retry:RetryEvent = new RetryEvent(RetryEvent.RETRY);
				retry.attempts       = this._attempts;
				
				this.dispatchEvent(retry);
				
				this._load();
			} else {
				super._complete();
				
				this.dispatchEvent(error);
			}
		}
		
		/**
			@sends Event#OPEN - Dispatched when a load operation starts.
		*/
		function _onOpen(e:Event):Void {
			this._latency = Std.int(Timer.stamp() - this._startTime);
			
			this.dispatchEvent(e);
		}
		
		function _onHttpStatus(e:HTTPStatusEvent):Void {
			this._httpStatus = e.status;
			
			this.dispatchEvent(e);
		}
		
		function _onProgress(progress:ProgressEvent):Void {
			this._calculateLoadProgress();
		}
		
		/**
			@sends LoadEvent#PROGRESS - Dispatched as data is received during the download process.
		*/
		function _calculateLoadProgress():Void {
			var currentTime:Float = Timer.stamp();
			
			this._Bps  = Std.int(LoadUtil.calculateBps(this.bytesLoaded, this._startTime, currentTime));
			this._time = Std.int(currentTime - this._startTime);
			
			this._progress.decimalPercentage = this.bytesLoaded / this.bytesTotal;
			
			this.dispatchEvent(this._createDefinedLoadEvent(LoadEvent.PROGRESS));
		}
		
		/**
			@sends LoadEvent#COMPLETE - Dispatched when file has completely loaded.
		*/
		function _onComplete(?complete:Event = null):Void {
			this._complete();
			
			this.dispatchEvent(this._createDefinedLoadEvent(LoadEvent.COMPLETE));
		}
		
		function _createDefinedLoadEvent(type:String):LoadEvent {
			var loadEvent:LoadEvent = new LoadEvent(type);
			loadEvent.attempts      = this.attempts;
			loadEvent.Bps           = this.Bps;
			loadEvent.bytesLoaded   = this.bytesLoaded;
			loadEvent.bytesTotal    = Std.int(this.bytesTotal);
			loadEvent.latency       = this.latency;
			loadEvent.progress      = this.progress;
			loadEvent.retries       = this.retries;
			loadEvent.time          = this.time;
			
			return loadEvent;
		}
		
		override function _complete():Void {
			var currentTime:Float            = Timer.stamp();
			this._Bps                        = Std.int(LoadUtil.calculateBps(Std.int(this.bytesTotal), Std.int(this._startTime), Std.int(currentTime)));
			this._time                       = Std.int(currentTime - this._startTime);
			this._loaded                     = true;
			this._progress.decimalPercentage = 1;
			
			super._complete();
		}
		
		function _dispatchEvent(e:Event) {
			this.dispatchEvent(e);
		}
	}
