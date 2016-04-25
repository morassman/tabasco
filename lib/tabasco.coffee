{$} = require 'atom-space-pen-views'
{CompositeDisposable} = require 'atom'
TabascoZone = require './tabasco-zone'
PaneListener = require './pane-listener'

module.exports = Tabasco =

  activate: (state) ->
    @disposables = new CompositeDisposable();
    @disposables.add atom.packages.onDidActivatePackage (pkg) => @packageActivated(pkg)
    @disposables.add atom.packages.onDidDeactivatePackage (pkg) => @packageDeactivated(pkg)
    @zones = [];
    @tabBarViews = [];
    @paneListeners = [];

    @sf = (e) => @onDragStart(e);
    @ef = (e) => @onDragEnd(e);

    if atom.packages.isPackageActive('tabs')
      @tabsActivated(atom.packages.getActivePackage('tabs'));

  deactivate: ->
    @tabsDeactivated();
    @disposables.dispose()

  packageActivated: (pkg) ->
    if pkg.name == 'tabs'
      @tabsActivated(pkg);

  packageDeactivated: (pkg) ->
    if pkg.name == 'tabs'
      @tabsDeactivated();

  tabsActivated: (@tabs) ->
    @paneDisposables = new CompositeDisposable();
    @paneDisposables.add atom.workspace.observePanes (pane) => @paneAdded(pane)
    @paneDisposables.add atom.workspace.onDidDestroyPane (event) => @paneRemoved(event.pane)
    @paneDisposables.add atom.workspace.onDidAddPaneItem => @removeZones()
    @paneDisposables.add atom.workspace.onDidDestroyPaneItem => @removeZones()

  tabsDeactivated: ->
    @tabs = null;
    @removeZones();
    @removeTabBarViews();
    @removePaneListeners();
    @paneDisposables?.dispose();

  paneAdded: (pane) ->
    @removeZones();

    if !@connectPaneWithTabBarView(pane)
      console.log("TabBarView not found. Adding listener.");
      paneListener = new PaneListener();
      @paneListeners.push(paneListener);
      paneListener.initialize(@, pane);

  paneRemoved: (pane) ->
    tbv = null;

    for tabBarView in @tabBarViews
      if tabBarView.pane == pane
        tbv = tabBarView;

    if tbv?
      @tabBarViewRemoved(tbv);

    paneListener = @getPaneListener(pane);

    if paneListener?
      @removePaneListener(paneListener);

    @removeZones();

  connectPaneWithTabBarView: (pane) ->
    for tabBarView in @tabs.mainModule.tabBarViews
      if tabBarView.pane == pane
        pane.onDidMoveItem => @removeZones();
        pane.onDidAddItem => @removeZones();
        pane.onDidRemoveItem => @removeZones();
        @tabBarViewAdded(tabBarView);
        return true;

    return false;

  getPaneListener: (pane) ->
    for paneListener in @paneListeners
      if paneListener.pane == pane
        return paneListener;

    return null;

  paneListenerTriggered: (paneListener) ->
    if @connectPaneWithTabBarView(paneListener.pane)
      @removePaneListener(paneListener);

  removePaneListener: (paneListener) ->
    index = @paneListeners.indexOf(paneListener);

    if index > -1
      @paneListeners.splice(index, 1);

    paneListener.dispose();

  removePaneListeners: ->
    for paneListener in @paneListeners
      paneListener.dispose();

    @paneListeners = [];

  tabBarViewAdded: (tabBarView) ->
    @tabBarViews.push(tabBarView);
    tabBarView.addEventListener 'dragstart', @sf
    tabBarView.addEventListener 'dragend', @ef

  tabBarViewRemoved: (tabBarView) ->
    index = @tabBarViews.indexOf(tabBarView);

    if index > -1
      @tabBarViews.splice(index, 1);

    @removeTabBarViewListener(tabBarView);

  removeTabBarViewListener: (tabBarView) ->
    tabBarView.removeEventListener 'dragstart', @sf
    tabBarView.removeEventListener 'dragend', @ef

  removeTabBarViews: ->
    for tabBarView in @tabBarViews
      @removeTabBarViewListener(tabBarView);

    @tabBarViews = [];

  onDragStart: (e) ->
    panes = atom.workspace.getPanes();
    activePane = atom.workspace.getActivePane();
    activePaneItem = atom.workspace.getActivePaneItem();
    workspaceView = atom.views.getView(atom.workspace);
    @zones = [];

    for pane in panes
      @addZones(activePane, activePaneItem, pane);

  onDragEnd: (e) ->
    @removeZones();

  removeZones: ->
    if @zones.length == 0
      return;

    for zone in @zones
      zone.remove();

    @zones = [];

  addZones: (activePane, activePaneItem, targetPane) ->
    centerOnly = !targetPane.getActiveItem()?

    if !centerOnly
      left = new TabascoZone();
      right = new TabascoZone();
      top = new TabascoZone();
      bottom = new TabascoZone();

      left.initialize(@, activePane, activePaneItem, targetPane, 'left');
      right.initialize(@, activePane, activePaneItem, targetPane, 'right');
      top.initialize(@, activePane, activePaneItem, targetPane, 'top');
      bottom.initialize(@, activePane, activePaneItem, targetPane, 'bottom');

      @zones.push(left);
      @zones.push(right);
      @zones.push(top);
      @zones.push(bottom);

    center = new TabascoZone();
    center.initialize(@, activePane, activePaneItem, targetPane, 'center', centerOnly);
    @zones.push(center);
