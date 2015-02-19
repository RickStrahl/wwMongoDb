# wwMongoDb ChangeLog

### Version 0.12
*released February 20th, 2015*

* **Add support for Aggregation Framework**<br/>
Added new Aggregate method that supports MongoDb Aggregation Pipeline commands to be sent to the collection. The aggregation framework allows for group/summarize functionality that otherwise is not available on regular query commands.

* **Miscellaneous bug fixes and documentation updates**</br>
Updated documentation to reflect latest changes in code interfaces. Minor code fixes adn doc clarifications based on user feedback.

### Version 0.11
*released Nov. 31st, 2014*

* **Add Delete support for delete JSON query document**<br/>
Added support for deleting by document in additon to the original delete by ID functionality.

* **wwMongoDb.GetCollection() to direct Access MongoDb Collection object**<br/>
Access to the collection object allows access to some core parameterless features like count(), removeAll(), drop() etc. 