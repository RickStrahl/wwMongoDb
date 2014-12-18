using System;
using System.Collections.Generic;
using System.Linq.Expressions;
using MongoDB.Bson;
using MongoDB.Bson.IO;
using MongoDB.Bson.Serialization;
using MongoDB.Driver;
using MongoDB.Driver.Builders;
using Westwind.Data.MongoDb.Properties;


namespace Westwind.Data.MongoDb
{

    public class MongoDbDataAccess : MongoDbDataAccess<object, Westwind.Data.MongoDb.MongoDbContext>
    {
        public MongoDbDataAccess(string connectionString) : base(connectionString: connectionString)
        { }        
    }

    /// <summary>
    /// Light weight Entity Framework Code First Business object base class
    /// that acts as a logic container for an entity DbContext instance. 
    /// 
    /// Subclasses of this business object should be used to implement most data
    /// related logic that deals with creating, updating, removing and querying 
    /// of data use EF Code First.
    /// 
    /// The business object provides base CRUD methods like Load, NewEntity,
    /// Remove that act on the specified entity type. The Save() method uses
    /// the EF specific context based SaveChanges
    /// which saves all pending changes (not just those for the current entity 
    /// and its relations). 
    /// 
    /// These business objects should be used as atomically as possible and 
    /// call Save() as often as possible to update pending data.
    /// </summary>
    /// <typeparam name="TEntity">
    /// The type of the entity that this business object is tied to. 
    /// Note that you can access any of the context's entities - this entity
    /// is meant as a 'top level' entity that controls the operations of
    /// the CRUD methods. Maps to the Entity property on this class
    /// </typeparam>
    /// <typeparam name="TMongoContext">
    /// A MongoDbContext type that configures MongoDb driver behavior and startup operation.
    /// </typeparam>
    public class MongoDbDataAccess<TEntity,TMongoContext>
        where TEntity : class, new()
        where TMongoContext : MongoDbContext, new()
    {
        /// <summary>
        /// Instance of the MongoDb core database instance.
        /// Set internally when the driver is initialized.
        /// </summary>
        public MongoDatabase Database { get; set; }

        protected string CollectionName { get; set; }        
        protected MongoDbContext Context = new MongoDbContext();

        /// <summary>
        /// Determines whether or not the Save operation causes automatic
        /// validation. Default is false.
        /// </summary>                        
        public bool AutoValidate { get; set; }

        /// <summary>
        /// Re-usable MongoDb Collection instance.
        /// Set internally when the driver is initialized
        /// and accessible after that.
        /// </summary>
        public MongoCollection<TEntity> Collection
        {
            get
            {
                if (_collection == null)
                    _collection = Database.GetCollection<TEntity>(CollectionName);
                return _collection;
            }
        }
        private MongoCollection<TEntity> _collection;


        /// <summary>
        /// Error Message set by the last operation. Check if 
        /// results of a method call return an error status.
        /// </summary>
        public string ErrorMessage
        {
            get
            {
                if (ErrorException == null)
                    return "";
                return ErrorException.Message;
            }
            set
            {
                if (string.IsNullOrEmpty(value))
                    ErrorException = null;
                else
                    // Assign a new exception
                    ErrorException = new ApplicationException(value);
            }
        }

        /// <summary>
        /// Instance of an exception object that caused the last error
        /// </summary>
        public Exception ErrorException
        {
            get { return _errorException; }
            set { _errorException = value; }
        }

        [NonSerialized] private Exception _errorException;


        #region ObjectInitializers
        

       
        /// <summary>
        /// Base constructor using default behavior loading context by 
        /// connectionstring name.
        /// </summary>
        /// <param name="connectionString">Connection string name</param>
        public MongoDbDataAccess(string collection = null, string database = null, string connectionString = null)
        {
            InitializeInternal();
            
            Context = new MongoDbContext();
            Database = GetDatabase(collection, database, connectionString);

            if (!Database.CollectionExists(CollectionName))
            {
                if (string.IsNullOrEmpty(CollectionName))
                    CollectionName = Pluralizer.Pluralize(typeof(TEntity).Name); 
                
                Database.CreateCollection(CollectionName);                
            }

            Initialize();
        }



        /// <summary>
        /// Specialized CreateContext that accepts a connection string and provider.
        /// Creates a new context based on a Connection String name or
        /// connection string.
        /// </summary>
        /// <param name="connectionString"></param>
        /// <returns></returns>
        /// <remarks>Important: 
        /// This only works if you implement a DbContext contstructor on your custom context
        /// that accepts a connectionString parameter.
        /// </remarks>
        protected virtual MongoDatabase GetDatabase(string collection = null,
            string database = null,
            string serverString = null)
        {

            var db = Context.GetDatabase(serverString,database);

            if (string.IsNullOrEmpty(collection))
                collection = Pluralizer.Pluralize(typeof(TEntity).Name);

            CollectionName = collection;
            
            return db;
        }



        /// <summary>
        /// Override to hook post Context intialization
        /// Fired by all constructors.
        /// </summary>
        protected virtual void Initialize()
        {
        }

        /// <summary>
        /// Internal common pre-Context creation initialization code
        /// fired by all constructors
        /// </summary>
        private void InitializeInternal()
        {
            // nothing to do yet, but we'll use this for sub objects
            // and potential meta data pre-parsing           
        }

   

        #endregion

        /// <summary>
        /// Finds an individual entity based on the entity tyep
        /// of this application.
        /// </summary>
        /// <param name="query"></param>
        /// <param name="collectionName"></param>
        /// <returns></returns>
        public TEntity FindOne(IMongoQuery query, string collectionName = null)
        {
            if (string.IsNullOrEmpty(collectionName))
                collectionName = CollectionName;

            return Database.GetCollection<TEntity>(collectionName).FindOne(query);
        }


        /// <summary>
        /// Finds an individual entity based on the entity type passed in
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <param name="query"></param>
        /// <param name="collectionName"></param>
        /// <returns></returns>
        public T FindOne<T>(IMongoQuery query, string collectionName = null)
        {
            if (string.IsNullOrEmpty(collectionName))
                collectionName = CollectionName;

            return Database.GetCollection<T>(collectionName).FindOne(query);
        }

        public IEnumerable<T> Find<T>(IMongoQuery query, string collectionName = null)
        {
            if (string.IsNullOrEmpty(collectionName))
                collectionName = CollectionName;

            return Database.GetCollection<T>(collectionName).Find(query);
        }

        /// <summary>
        /// Allows you to query for a single entity  using a Mongo Shell query 
        /// string. Uses the default entity defined.
        /// </summary>
        /// <param name="jsonQuery">Json object query string</param>
        /// <param name="collectionName">Optional - name of the collection to search</param>
        /// <returns>Collection of items or null if none</returns>
        public TEntity FindOneFromString(string jsonQuery, string collectionName = null)
        {
            if (string.IsNullOrEmpty(collectionName))
                collectionName = CollectionName;

            var query = GetQueryFromString(jsonQuery);
            return Database.GetCollection<TEntity>(collectionName).FindOne(query);
        }

        /// <summary>
        /// Allows you to query for a single entity  using a Mongo Shell query 
        /// string. Uses the entity type passed.
        /// </summary>
        /// <param name="jsonQuery">Json object query string</param>
        /// <param name="collectionName">Optional - name of the collection to search</param>
        /// <returns>Collection of items or null if none</returns>
        public T FindOneFromString<T>(string jsonQuery, string collectionName = null)
        {
            if (string.IsNullOrEmpty(collectionName))
                collectionName = CollectionName;

            var query = GetQueryFromString(jsonQuery);
            return Database.GetCollection<T>(collectionName).FindOne(query);
        }

        /// <summary>
        /// Allows you to query for a single entity  using a Mongo Shell query 
        /// string. Uses the entity type passed.
        /// </summary>
        /// <param name="jsonQuery">Json object query string</param>
        /// <param name="collectionName">Optional - name of the collection to search</param>
        /// <returns>Collection of items or null if none</returns>
        public string FindOneFromStringJson(string jsonQuery, string collectionName = null)
        {
            if (string.IsNullOrEmpty(collectionName))
                collectionName = CollectionName;

            var query = GetQueryFromString(jsonQuery);
            var cursor = Database.GetCollection(collectionName).FindOne(query);
            
            if (cursor == null)
                return null;

            return cursor.ToJson( new JsonWriterSettings { OutputMode = JsonOutputMode.Strict });
        }
   
   
        public IEnumerable<TEntity> FindAll(string collectionName = null)
        {
            if (string.IsNullOrEmpty(collectionName))
                collectionName = CollectionName;

            return Database.GetCollection<TEntity>(collectionName).FindAll();
        }

        public IEnumerable<T> FindAll<T>(string collectionName = null)
        {
            if (string.IsNullOrEmpty(collectionName))
                collectionName = CollectionName;

            return Database.GetCollection<T>(collectionName).FindAll();
        }

        

        public IEnumerable<TEntity>FindFromString(string jsonQuery, string collectionName = null)
        {
            if (string.IsNullOrEmpty(collectionName))
                collectionName = CollectionName;

            var query = GetQueryFromString(jsonQuery);
            var items = Database.GetCollection<TEntity>(collectionName).Find(query);
            
            return items;
        }
       

        /// <summary>
        /// Allows you to query Mongo using a Mongo Shell query 
        /// string and explicitly specify the result type.
        /// </summary>
        /// <param name="jsonQuery">Json object query string</param>
        /// <param name="collectionName">Optional - name of the collection to search</param>
        /// <returns>Collection of items or null if none</returns>    
        public IEnumerable<T> FindFromString<T>(string jsonQuery, string collectionName = null,
                                                int skip = -1, int limit = -1)
        {
            if (string.IsNullOrEmpty(collectionName))
                collectionName = CollectionName;

            var query = GetQueryFromString(jsonQuery);                        
            var items = Database.GetCollection<T>(collectionName).Find(query);

            return items;
        }

        /// <summary>
        /// Allows you to query Mongo using a Mongo Shell query 
        /// string.
        /// </summary>
        /// <param name="jsonQuery">Json object query string</param>
        /// <param name="collectionName">Optional - name of the collection to search</param>
        /// <returns>Collection of items or null if none</returns>
        public string FindFromStringJson(string jsonQuery, string collectionName = null,
            int skip = -1, int limit = -1)
        {
            if (string.IsNullOrEmpty(collectionName))
                collectionName = CollectionName;

            var query = GetQueryFromString(jsonQuery);
            var cursor = Database.GetCollection(collectionName).Find(query);

            if (limit > -1)
                cursor.Limit = limit;

            if (skip > -1)
                cursor.Skip = skip;            

            return cursor.ToJson( new JsonWriterSettings { OutputMode = JsonOutputMode.Strict } );
        }

        /// <summary>
        /// Allows you to query Mongo using a Mongo Shell query 
        /// by providing a .NET object that is translated into
        /// the appropriate JSON/BSON structure. 
        /// 
        /// This might be easier to write by hand than JSON strings
        /// in C# code.
        /// </summary>
        /// <param name="queryObject">Any .NET object that conforms to Mongo query object structure</param>
        /// <param name="collectionName">Optional - name of the collection to search</param>
        /// <returns>Collection of items or null if none</returns>
        public IEnumerable<TEntity> FindFromObject(object queryObject, string collectionName = null)
        {
            if (string.IsNullOrEmpty(collectionName))
                collectionName = CollectionName;

            var query = new QueryDocument(queryObject.ToBsonDocument());
            var items = Database.GetCollection<TEntity>(collectionName).Find(query);

            return items;
        }

        /// <summary>
        /// Allows you to query Mongo using a Mongo Shell query 
        /// by providing a .NET object that is translated into
        /// the appropriate JSON/BSON structure. This version
        /// allows you to specify the result type explicitly.
        /// 
        /// This might be easier to write by hand than JSON strings
        /// in C# code.
        /// </summary>
        /// <param name="queryObject">Any .NET object that conforms to Mongo query object structure</param>
        /// <param name="collectionName">Optional - name of the collection to search</param>
        /// <returns>Collection of items or null if none</returns>
        public IEnumerable<T> FindFromObject<T>(object queryObject, string collectionName = null)
        {
            if (string.IsNullOrEmpty(collectionName))
                collectionName = CollectionName;

            var query = new QueryDocument(queryObject.ToBsonDocument());
            var items = Database.GetCollection<T>(collectionName).Find(query);

            return items;
        }

        /// <summary>
        /// Creates a Bson Query document from a Json String.
        /// 
        /// You can pass this as a Query operation to any of the
        /// Collection methods that expect a query.
        /// </summary>
        /// <param name="jsonQuery"></param>
        /// <returns></returns>
        public QueryDocument GetQueryFromString(string jsonQuery)
        {            
            return new QueryDocument(BsonSerializer.Deserialize<BsonDocument>(jsonQuery));
        }



        /// <summary>
        /// Loads in instance based on its string id
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        public TEntity Load(string id)
        {
            return LoadBase(id);
        }

        /// <summary>
        /// Loads in instance based on its string id
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        public TEntity Load(int id)
        {
            return LoadBase(id);
        }

        /// <summary>
        /// Loads an instance based on its key field id
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        protected virtual TEntity LoadBase(string id)
        {
            var entity = Collection.FindOneByIdAs(typeof(TEntity), new BsonString(id)) as TEntity;            

            if (entity == null)
            {
                SetError("No match found.");
                return null;
            }
        
            return entity;
        }


        /// <summary>
        /// Loads an instance based on its key field id
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        protected virtual TEntity LoadBase(int id)
        {
            var entity = Collection.FindOneByIdAs(typeof(TEntity),  id) as TEntity;

            if (entity == null)
            {
                SetError("No match found.");
                return null;
            }
            return entity;
        }

        /// <summary>
        /// Loads an entity based on a Lambda expression
        /// </summary>
        /// <param name="whereClauseLambda"></param>
        /// <returns></returns>
        protected virtual TEntity LoadBase(Expression<Func<TEntity, bool>> whereClauseLambda)
        {
            SetError();
            TEntity entity;

            try
            {
                var query = Query<TEntity>.Where(whereClauseLambda);
                entity = Database.GetCollection<TEntity>(CollectionName).FindOne(query);

                return entity;
            }
            catch (InvalidOperationException)
            {
                // Handles errors where an invalid Id was passed, but SQL is valid
                SetError(Resources.CouldntLoadEntityInvalidKeyProvided);
                return null;
            }
            catch (Exception ex)
            {
                // handles Sql errors                                
                SetError(ex);
            }

            return null;
        }


        /// <summary>
        /// Loads an entity and returns a JSON string
        /// </summary>
        /// <param name="id"></param>
        /// <param name="collection"></param>
        /// <returns></returns>
        public string LoadJson(string id, string collection)
        {
            return FindOneFromStringJson(string.Format("{{ _id: '{0}' }}", id), collection);
        }

        /// <summary>
        /// Loads an entity and returns a JSON string
        /// </summary>
        /// <param name="id">A string ID or Object Id value to look up</param>
        /// <param name="collection"></param>
        /// <returns></returns>
        public string LoadJson(int id, string collection)
        {
            return FindOneFromStringJson(string.Format("{ _id: {0} }", id), collection);
        }


        /// <summary>
        /// removes an individual entity instance.
        /// 
        /// This method allows specifying an entity in a dbSet other
        /// then the main one as long as it's specified by the dbSet
        /// parameter.
        /// </summary>
        /// <param name="entity"></param>
        /// <param name="dbSet">Optional - 
        /// Allows specifying the Collection to which the entity passed belongs.
        /// If not specified the current Collection for the current entity is used </param>
        /// <param name="saveChanges">Optional - 
        /// If true does a Context.SaveChanges. Set to false
        /// when other changes in the Context are pending and you don't want them to commit
        /// immediately
        /// </param>
        /// <param name="noTransaction">Optional - 
        /// If true the Delete operation is wrapped into a TransactionScope transaction that
        /// ensures that OnBeforeDelete and OnAfterDelete all fire within the same Transaction scope.
        /// Defaults to false as to improve performance.
        /// </param>
        public virtual bool Delete(TEntity entity)
        {
            if (entity == null)
                return true;

            if (!DeleteInternal(entity))
                return false;

            return true;
        }


        /// <summary>
        /// Deletes an entity from the main entity set
        /// based on a key value.
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        public virtual bool Delete(string id)
        {
            var query = Query.EQ("_id", new BsonString(id));
            var result = Collection.Remove(query);
            if (result.HasLastErrorMessage)
            {
                SetError(result.ErrorMessage);
                return false;
            }
            return true;
        }

        public virtual bool Delete(int id)
        {
            var query = Query.EQ("_id", id);
            var result = Collection.Remove(query);
            if (result.HasLastErrorMessage)
            {
                SetError(result.ErrorMessage);
                return false;
            }
            return true;
        }

        /// <summary>
        /// Actual delete operation that removes an entity
        /// </summary>
        private bool DeleteInternal(TEntity entity)
        {
            try
            {
                var query = Query.EQ("_id", new BsonString(((dynamic) entity).Id.ToString()));
                var result = Collection.Remove(query);

                if (result.HasLastErrorMessage)
                {
                    SetError(result.ErrorMessage);
                    return false;
                }                
            }
            catch (Exception ex)
            {
                SetError(ex, true);
                return false;
            }

            return true;
        }


        /// <summary>
        /// Saves all changes. 
        /// </summary>
        /// <remarks>
        /// This method calls Context.SaveChanges() so it saves
        /// all changes made in the context not just changes made
        /// to the current entity. It's crucial to Save() as
        /// atomically as possible or else use separate Business
        /// object instances with separate contexts.
        /// </remarks>
        /// <returns></returns>
        public bool Save(TEntity entity, string collectionName = null)
        {
            if (string.IsNullOrEmpty(collectionName))
                collectionName = CollectionName;

            if (entity == null)
                throw new ArgumentException("Entity has to be passed in.");

            try
            {
                var result = Collection.Save(entity);
                if (result.HasLastErrorMessage)
                {
                    SetError(result.LastErrorMessage);
                    return false;
                }
            }
            catch (Exception ex)
            {
                SetError(ex, true);
                return false;
            }

            return true;
        }

        /// <summary>
        /// Saves an entity based on a provided type.
        /// </summary>
        /// <remarks>
        /// This version of Save() does not run Validation, or
        /// before and after save events since it's not tied to
        /// the current entity type. If you want the full featured
        /// save use the non-generic Save() operation.
        /// </remarks>
        /// <returns></returns>
        public bool Save<T>(T entity, string collectionName = null) 
            where T: class, new()
        {
            if (string.IsNullOrEmpty(collectionName))
                collectionName = Pluralizer.Pluralize(typeof(T).Name);

            if (entity == null)
            {
                SetError("No entity to save passed.");
                return false;
            }

            try
            {
                var result = Database.GetCollection(collectionName).Save(entity);
                if (result.HasLastErrorMessage)
                {
                    SetError(result.LastErrorMessage);
                    return false;
                }
            }
            catch (Exception ex)
            {
                SetError(ex, true);
                return false;
            }
            
            return true;
        }

        /// <summary>
        /// Saves 
        /// </summary>
        /// <param name="entity"></param>
        /// <param name="collectionName"></param>
        /// <returns>Id of object saved</returns>
        public MongoSaveResponse SaveFromJson(string entityJson, string collectionName = null)
        {
            if (string.IsNullOrEmpty(collectionName))
                collectionName = CollectionName;

            if (string.IsNullOrEmpty(entityJson))
            {
                SetError("No entity to save passed.");
                return null;
            }

            try
            {
                var doc = BsonDocument.Parse(entityJson);
                if (doc == null)
                {
                    SetError("No entity to save passed.");
                    return null;
                }

                var result = Database.GetCollection(collectionName).Save(doc); //, new SafeMode(true));
                if (result.HasLastErrorMessage)
                {
                    SetError(result.LastErrorMessage);
                    return null;
                }

                return new MongoSaveResponse
                {
                    Id = doc["_id"].ToString(),
                    Ok = !result.HasLastErrorMessage,
                    Message = result.LastErrorMessage
                };
            }
            catch (Exception ex)
            {
                SetError(ex, true);
                return null;
            }
            
        }

        /// <summary>
        /// Generates a new Bson Id and returns it as a string.
        /// This function can be used by non-.NET clients/APIs
        /// that only work with string values.
        /// </summary>
        /// <returns>string</returns>
        public string GenerateNewId()
        {
            return ObjectId.GenerateNewId().ToString();
        }


        /// <summary>
        /// Sets an internal error message.
        /// </summary>
        /// <param name="Message"></param>
        public void SetError(string Message)
        {
            if (string.IsNullOrEmpty(Message))
            {
                ErrorException = null;
                return;
            }

            ErrorException = new ApplicationException(Message);

            //if (Options.ThrowExceptions)
            //    throw ErrorException;

        }

        /// <summary>
        /// Sets an internal error exception
        /// </summary>
        /// <param name="ex"></param>
        public void SetError(Exception ex, bool checkInnerException = false)
        {
            ErrorException = ex;

            if (checkInnerException)
            {
                while (ErrorException.InnerException != null)
                {
                    ErrorException = ErrorException.InnerException;
                }
            }

            ErrorMessage = ErrorException.Message;
            //if (ex != null && Options.ThrowExceptions)
            //    throw ex;
        }

        /// <summary>
        /// Clear out errors
        /// </summary>
        public void SetError()
        {
            ErrorException = null;
            ErrorMessage = null;
        }

        /// <summary>
        /// Overridden to display error messages if one exists
        /// </summary>
        /// <returns></returns>
        public override string ToString()
        {
            if (!string.IsNullOrEmpty(ErrorMessage))
                return "Error: " + ErrorMessage;

            return base.ToString();
        }

        private bool disposed;

        public void Dispose()
        {
            if (disposed)
                return;

            disposed = true;

            if (Database != null)
            {
                Database = null;
            }
        }
    }

    public class MongoSaveResponse
    {
        public string Id { get; set; }
        public bool Ok { get; set; }
        public string Message { get; set; }
    }
}