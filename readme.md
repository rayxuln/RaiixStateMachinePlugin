# Raiix StateMachine Plugin for Godot

[简体中文](./readme_ch.md)

## Features

- Each StateMachine and State is a node
- A State can have a sub StateMachine
- The transition is a condition expression string that will be executed every frame to determine whether or not to change the state
- A StateMachineResource Editor
- A StateMachine Remote Viewer

## How to Use

You can run the demo scene from `scenes/RaiixStateMachineTest.tscn`, then open the RemoteViewer window by menu `Project/Tools/State MachineRemote Viewer`. To inspect the infomation about a StateMachine node, double-click a StateMachine node, and then you are able to switch the state.

![StateMachine Remote Viewer](./images/remote_viewer.gif)

To edit the StateMachineResource, select the StateMachine node in the scene tree tab. Then you can add/remove/connect/edit states.

![StateMachineResource Editor](./images/sm_edit.png)

To create a new StateMachine, just add a StateMachine node to the scene, and edit it in the StateMachineResource editor.

## Known Issue (If the plugin is working weirdly, please read below)

Every time open the project with this plugin enabled, save the project (Press `ctr+s` or `cmd+s`) before doing anything. Then disable this plugin and an error will show up. Just ignore it and enable this plugin again, and every things just go normally and do whatever you want to do with this plugin.

I really have no idea why there will be an error and it only shows up every time I open the project.

## How Does the StateMachine Remote Viewer Work

The plugin will add an `AutoLoad` node, the `RemoteDebugClient`, and add the `RemoteDebugServer` node as its own child.

The `RemoteDebugServer` is a TCP server and will listen on port `25561`.

The `RemoteDebugClient` will be auto loaded when any scene starts playing, and connect to the server through port `25561`.

And the server will state communicating with the client when you open the StateMachine Remote Viewer. The server will ask for the scene tree info of the client, and the info of the specific StateMachine node. Then the StateMachine Remote Viewer just presents them to you.

> If you want to disable this feature, just change the value of `enable` to `false` by editing the file, 'res://addons/raiix_statemachine/RemoteDebug/RemoteDebugClient.gd'. The `RemoteDebugClient` will be removed automaticly when the game runs.
