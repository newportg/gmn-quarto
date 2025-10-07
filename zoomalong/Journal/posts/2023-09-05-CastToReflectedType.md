---
title: Cast To a Reflected Type
Published: 2023/09/05
Tags: C#
---

How many times do you find yourselves not knowing the type of a object, and wanting to cast it.

In my senario, I was working in a table storage library, and I was trying to merge json objects.
The issue being, in the library you have no visibility of the data structure, so you have to use reflection.

entity is the object to be merged.
mergedJson is the merged json object.

The issue here is the Update method takes a object of TableEntity. If you simply map to a table entity then your object will be missing the data.
So in this case you get the type of the passed 'entity' in this case AddressDto 
after you have merged the json you need to deserailise it back into a object.
The issue is the deserialise object is of type object and not TableEntity.
The ObjectExtensions code was obtain, and performs the cast correctly and creates a eek object of type AddressDto, which is good to update.

```C#
    Type objectType = entity.GetType();
    var merged2 = JsonConvert.DeserializeObject(mergedJson, objectType);
    var eek = ObjectExtensions.CastToReflected(merged2, objectType);
    res = Update(eek);


    public static class ObjectExtensions
    {
        public static T CastTo<T>(this object o) => (T)o;

        public static dynamic CastToReflected(this object o, Type type)
        {
            var methodInfo = typeof(ObjectExtensions).GetMethod(nameof(CastTo), BindingFlags.Static | BindingFlags.Public);
            var genericArguments = new[] { type };
            var genericMethodInfo = methodInfo?.MakeGenericMethod(genericArguments);
            return genericMethodInfo?.Invoke(null, new[] { o });
        }
    }
```