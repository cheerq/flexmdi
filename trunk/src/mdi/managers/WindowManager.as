package mdi.managers
{	

	import flash.display.DisplayObject;
	import flash.geom.Point;
	
	import mx.containers.Panel;
	import mx.controls.Alert;
	import mx.core.Application;
	import mx.core.IFlexDisplayObject;
	import mx.core.UIComponent;
	import mx.effects.WipeDown;
	import mx.managers.PopUpManager;
	import mx.utils.ArrayUtil;
	

	import mdi.containers.Window;
	import mdi.events.WindowEvent;
	import mx.core.Container;
	import mx.managers.PopUpManagerChildList;
	import flash.ui.ContextMenu;
	import flash.events.ContextMenuEvent;
	import flash.ui.ContextMenuItem;
	import mx.effects.Effect;
	
	
	public class WindowManager
	{	
		
		private static var globalWindowManager : WindowManager;
		public static function get global():WindowManager
		{
			if( WindowManager.globalWindowManager == null)
				globalWindowManager = new WindowManager(Application.application as DisplayObject);
			return WindowManager.globalWindowManager;
		}
		
		
		private var _parent : DisplayObject;
		public function WindowManager(parent:DisplayObject,showEffect:Effect=null):void
		{
			_parent = parent;
		}
		
		
		public var showEffect : Effect;
		
		
		/**
     	*  @private
     	*  the managed window stack
     	*/
		private var windowList:Array = new Array();

		public function add(window:Window):void
		{	
			this.windowList.push(window);

			window.addEventListener(WindowEvent.CLOSE,windowCloseEventHandler);
			window.addEventListener(WindowEvent.MINIMIZE,windowMinimizeHandler);
			
			this.addContextMenu(window);
			
			
			
			PopUpManager.addPopUp(window,this._parent,false,PopUpManagerChildList.PARENT);
			position(window); 
			
			if(window.showEffect != null)
			{	
				window.showEffect.target = window;
				window.showEffect.play();
			}
			
		}
		
		public function addContextMenu(window:Window,contextMenu:ContextMenu=null):void
		{
			
			// add default context menu 
			if(contextMenu == null)
			{
				var defaultContextMenu : ContextMenu = new ContextMenu();
					defaultContextMenu.hideBuiltInItems();

			
				var item1:ContextMenuItem = new ContextMenuItem("Auto Arrange");
			  		item1.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, menuItemSelectHandler);
					defaultContextMenu.customItems.push(item1);

           	 	var item2:ContextMenuItem = new ContextMenuItem("Auto Arrange Fill");
			  		item2.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, menuItemSelectHandler);
                   	defaultContextMenu.customItems.push(item2);  
                   	
                var item3:ContextMenuItem = new ContextMenuItem("Cascade");
			  		item3.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, menuItemSelectHandler);
                   	defaultContextMenu.customItems.push(item3);
                   	
                var item4:ContextMenuItem = new ContextMenuItem("Close");
			  		item4.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, menuItemSelectHandler);
                   	defaultContextMenu.customItems.push(item4);  
            	     
            	window.contextMenu = defaultContextMenu;
			}
			else
			{	
				// add passed in context menu
				window.contextMenu = contextMenu;
			}
		}
		
		
		private function menuItemSelectHandler(event:ContextMenuEvent):void
		{
			switch(event.target.caption)
			{
				case("Auto Arrange"):
					this.tile();
				break;
				
				case("Auto Arrange Fill"):
					this.tile(true);
				break;
				
				case("Cascade"):
					this.cascade();
				break;
				
				case("Close"):
					this.remove(event.contextMenuOwner as Window);
				break;
				
			}
			
			
			
		}
		
		private function windowMinimizeHandler(event:WindowEvent):void
		{
			// implement minimize functionality
		}
		
		private function windowCloseEventHandler(event:WindowEvent):void
		{
			if(this.windowList.indexOf( event.window) > -1)
			{
				this.remove(event.window);
			}
		}
		
		
		public function addCenter(window:Window):void
		{
			
			this.add(window);
			this.center(window);
		
		}
		
		
		/**
		 * Brings a window to the front of the screen. 
		 * 
		 *  @param win Window to bring to front
		 * */
		public function bringToFront(window:Window):void
		{
			PopUpManager.bringToFront(window);
		}
		
		
		/**
		 * Positions a window in the center of the available screen. 
		 * 
		 *  @param win Window to center
		 * */
		public function center(window:Window):void
		{
			PopUpManager.centerPopUp(window);
			PopUpManager.bringToFront(window);
		}
		
		
		/**
		 * Removes all windows from managed window stack; 
		 * */
		public function removeAll():void
		{	
		
			for each(var window:Window in windowList)
			{
				//remove(win);
				PopUpManager.removePopUp(window);
			}
			this.windowList = new Array();
		}

		
		/**
		 *  Removes a window instance from the managed window stack 
		 *  @param win:IFlexDisplayObject Window to remove 
		 */
		public function remove(window:Window):void
		{	
			
			var index:int = ArrayUtil.getItemIndex(window, windowList);
			windowList.splice(index, 1);
			PopUpManager.removePopUp(window);
		}
		
		
				
		
		/**
		 * Pushes a window onto the managed window stack 
		 * 
		 *  @param win Window to push onto managed windows stack 
		 * */
		public function pushWindowOnStack(win:Window):void
		{	
			if(win != null)
				windowList.push(win);
		}
		
		/**
		 *  Positions a window in an absolute position 
		 * 
		 *  @param win:IFlexDisplayObject Window to position
		 * 
		 *  @param x:int The x position of the window
		 * 
		 *  @param y:int The y position of the window 
		 */
		public function absPos(window:Window,x:int,y:int):void
		{
			window.x = x;
			window.y = y;		
		}
		
		
		/**
		 *  Tiles the window across the screen
		 *  
		 *  <p>By default, windows will be tiled to all the same size and use only the space they can accomodate.
		 *  If you set fillSpace = true, tile will use all the space available to tile the windows with
		 *  the windows being arranged by varying heights and widths. 
     	 *  </p>
		 * 
		 *  @param fillSpace:Boolean Variable to determine whether to use the fill the entire available screen
		 * 
		 */
		public function tile(fillSpace:Boolean = false):void
		{
			
			
			var numWindows:int = this.windowList.length;
			var sqrt:int = Math.round(Math.sqrt(numWindows));
			var numCols:int = Math.ceil(numWindows / sqrt);
			var numRows:int = Math.ceil(numWindows / numCols);
			var col:int = 0;
			var row:int = 0;
			var availWidth:Number = this._parent.width;
			var availHeight:Number = this._parent.height;
			var targetWidth:Number = availWidth / numCols;
			var targetHeight:Number = availHeight / numRows;
			
						
			for(var i:int = 0; i < this.windowList.length; i++)
			{
				var win:Window = this.windowList[i];
				win.width = targetWidth;
				win.height = targetHeight;
				
				if(i > 0)
				{
					var prevWin:Window = this.windowList[i - 1];
				}				
				
				if(i % numCols == 0 && i > 0)
				{
					row++;
					col = 0;
				}
				else if(i > 0)
				{
					col++;
				}
				//positin window within parent
				win.x = this._parent.x + (col * targetWidth);
				win.y = this._parent.y + (row * targetHeight);
			}
			
			if(col < numCols && fillSpace)
			{
				var numOrphans:int = numWindows % numCols;
				var orphanWidth:Number = availWidth / numOrphans;
				for(var j:int = numWindows - numOrphans; j < numWindows; j++)
				{
					var orphan:Window = this.windowList[j];
					orphan.width = orphanWidth;
					orphan.x = this._parent.x + (j - (numWindows - numOrphans)) * orphanWidth;
				}
			}
		}
		
		
		
		
		
		
		/**
		 *  Positions a window on the screen 
		 *  
		 * 	<p>This is primarly used as the default space on the screen to position the window.</p>
		 * 
		 *  @param window:IFlexDisplayObject Window to position
		 */
		public function position(window:Window):void
		{	
			
			
			var x:int =  this.windowList.length * 20;
			var y:int =  this.windowList.length * 20;
			
			var point : Point = new Point(x,y);
			var local : Point = this._parent.localToGlobal(point);
	

			window.x = local.x;
			window.y = local.y;

			// cycle back around
			if( (window.x + window.width) > this._parent.width ) window.x = 40;
			if( (window.y + window.height) > this._parent.height ) window.y = 40;
		}
		
		// set a min. width/height
		public function resize(window:Window):void
		{	
		
			var w:int = this._parent.width * .6;
			var h:int = this._parent.height * .6
			if( w > window.width )
				window.width = w;
			if( h > window.height )
				window.height=h;
		}
		
		
		
		
		
		
		
		/**
		 *  Maximizes a window to use all available space
		 * 
		 *  @param window:IFlexDisplayObject Window to maximize
		 */
		public function maximize(window:Window):void
		{					
			
			window.x=10;
			window.y=40;
			window.width = this._parent.width - 20;
			window.height = this._parent.height - 60;
			
			//make sure window is on top.
			PopUpManager.bringToFront(window as IFlexDisplayObject);	
		}
		
		
		
		
		
		
		/**
		 *  Cascades all managed windows from top left to bottom right 
		 * 
		 *  @param window:IFlexDisplayObject Window to maximize
		 */	
		public function cascade():void
		{
			for(var i:int=0; i < this.windowList.length; i++)
			{
				var win : Window = this.windowList[i] as Window;
				PopUpManager.bringToFront(win);
				win.x = this._parent.x + i * 40;
				win.y = this._parent.y + i * 40;
			}
		}
		
		
	}
}