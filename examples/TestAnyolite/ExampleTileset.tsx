<?xml version="1.0" encoding="UTF-8"?>
<tileset version="1.10" tiledversion="1.10.2" name="ExampleTileset" tilewidth="50" tileheight="50" tilecount="8" columns="2">
 <image source="ExampleTileset.png" width="100" height="200"/>
 <tile id="0">
  <properties>
    <property name="no_collision" type="bool" value="true"/>
    </properties>
 </tile>
 <tile id="2">
  <properties>
   <property name="crunchy" type="bool" value="true"/>
  </properties>
 </tile>
 <tile id="4">
 <animation>
   <frame tileid="4" duration="500"/>
   <frame tileid="5" duration="500"/>
  </animation>
  <properties>
   <property name="water" type="bool" value="true"/>
   <property name="solid" type="bool" value="true"/>
  </properties>
 </tile>
 <tile id="5">
  <properties>
   <property name="water" type="bool" value="true"/>
   <property name="solid" type="bool" value="true"/>
  </properties>
 </tile>
 <tile id="6">
  <properties>
   <property name="solid" type="bool" value="true"/>
  </properties>
 </tile>
  <tile id="7">
  <properties>
   <property name="solid" type="bool" value="false"/>
   <property name="harmful" type="bool" value="true"/>
  </properties>
 </tile>
</tileset>
