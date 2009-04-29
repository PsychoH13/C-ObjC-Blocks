#include "blocks_runtime.h"

struct StackBlockClass;
struct GlobalBlockClass;

void *__Block_copy(void *);
void __Block_release(void *);

// Descriptor attributes
enum {
    BLOCK_HAS_COPY_DISPOSE =  (1 << 25),
    BLOCK_HAS_CTOR =          (1 << 26), // helpers have C++ code
    BLOCK_IS_GLOBAL =         (1 << 28),
    BLOCK_HAS_DESCRIPTOR =    (1 << 29), // interim until complete world build is accomplished
};

// _Block_object_assign() and _Block_object_dispose() flag helpers.
enum {
    BLOCK_FIELD_IS_OBJECT   =  3,  // id, NSObject, __attribute__((NSObject)), block, ...
    BLOCK_FIELD_IS_BLOCK    =  7,  // a block variable
    BLOCK_FIELD_IS_BYREF    =  8,  // the on stack structure holding the __block variable
    
    BLOCK_FIELD_IS_WEAK     = 16,  // declared __weak
    
    BLOCK_BYREF_CALLER      = 128, // called from byref copy/dispose helpers
};

// Helper structure
struct psy_block_literal {
    void *isa; // initialized to &_NSConcreteStackBlock or &_NSConcreteGlobalBlock
    int flags;
    int reserved;
    void (*invoke)(void *, ...);
    struct {
        unsigned long int reserved;	// NULL
    	unsigned long int size;  // sizeof(struct Block_literal_1)
        // optional helper functions
    	void (*copy_helper)(void *dst, void *src);
    	void (*dispose_helper)(void *src); 
    } *descriptor;
};

// Helper structure
struct psy_block_byref_obj {
    void *isa;  // uninitialized
    struct psy_block_byref_obj *forwarding;
    int flags;   //refcount;
    int size;
    void (*byref_keep)(struct psy_block_byref_obj *dst, struct psy_block_byref_obj *src);
    void (*byref_dispose)(struct psy_block_byref_obj *);
};

/* Certain field types require runtime assistance when being copied to the heap.  The following function is used
 * to copy fields of types: blocks, pointers to byref structures, and objects (including __attribute__((NSObject)) pointers.
 * BLOCK_FIELD_IS_WEAK is orthogonal to the other choices which are mutually exclusive.
 * Only in a Block copy helper will one see BLOCK_FIELD_IS_BYREF.
 */
void _Block_object_assign(void *destAddr, void *object, const int flags)
{
    printf("%s\n", __func__);
    // FIXME: Needs to be implemented
    if(flags & BLOCK_FIELD_IS_WEAK)
    {
    }
    else
    {
        if(flags & BLOCK_FIELD_IS_BYREF)
        {
            struct psy_block_byref_obj *src = object;
            struct psy_block_byref_obj **dst = destAddr;
            /* I followed Apple's specs saying byref's "flags" field should represent the refcount
             * but it still contains real flag, so this is a little hack...
             */
            if((src->flags & ~BLOCK_HAS_COPY_DISPOSE) == 0)
            {
                *dst = malloc(src->size);
                memcpy(*dst, src, src->size);
                
                if(src->size >= sizeof(struct psy_block_byref_obj))
                    src->byref_keep(*dst, src);
            }
            else *dst = src;
            
            (*dst)->flags++;
        }
        else if((flags & BLOCK_FIELD_IS_BLOCK) == BLOCK_FIELD_IS_BLOCK)
        {
            struct psy_block_literal *src = object;
            struct psy_block_literal **dst = destAddr;
            
            *dst = __Block_copy(src);
        }
        else if((flags & BLOCK_FIELD_IS_BLOCK) == BLOCK_FIELD_IS_OBJECT)
        {
            id src = object;
            id *dst = destAddr;
            *dst = [src retain];
        }
    }
}

/* Similarly a compiler generated dispose helper needs to call back for each field of the byref data structure.
 * (Currently the implementation only packs one field into the byref structure but in principle there could be more).
 * The same flags used in the copy helper should be used for each call generated to this function:
 */
void _Block_object_dispose(void *object, const int flags)
{
    printf("%s\n", __func__);
    // FIXME: Needs to be implemented
    if(flags & BLOCK_FIELD_IS_WEAK)
    {
    }
    else
    {
        if(flags & BLOCK_FIELD_IS_BYREF)
        {
            struct psy_block_byref_obj *src = object;
            
            src->flags--;
            if((src->flags & ~BLOCK_HAS_COPY_DISPOSE) == 0)
            {
                if(src->size >= sizeof(struct psy_block_byref_obj))
                    src->byref_dispose(src);
                
                free(src);
            }
        }
        else if((flags & ~BLOCK_BYREF_CALLER) == BLOCK_FIELD_IS_BLOCK)
        {
            struct psy_block_literal *src = object;
            __Block_release(src);
        }
        else if((flags & ~BLOCK_BYREF_CALLER) == BLOCK_FIELD_IS_OBJECT)
        {
            id src = object;
            [src release];
        }
    }
}

// The following code is generated with clang-cc -rewrite-objc and provides Blocks with an isa
// pointer compatible with Apple's ObjC runtime.

#ifndef _REWRITER_typedef_StackBlockClass
#define _REWRITER_typedef_StackBlockClass
typedef struct objc_object StackBlockClass;
#endif

struct StackBlockClass {
    void *isa; // initialized to &_NSConcreteStackBlock or &_NSConcreteGlobalBlock
    int flags;
    int reserved;
    void (*invoke)(void *, ...);
    struct {
        unsigned long int reserved;	// NULL
    	unsigned long int size;  // sizeof(struct Block_literal_1)
        // optional helper functions
    	void (*copy_helper)(void *dst, void *src);
    	void (*dispose_helper)(void *src); 
    } *descriptor;
};

// @end

// @implementation StackBlockClass

static id _I_StackBlockClass_retain(struct StackBlockClass * self, SEL _cmd)
{
    return __Block_copy(self);
}

static id _I_StackBlockClass_copy(struct StackBlockClass * self, SEL _cmd)
{
    return _I_StackBlockClass_retain(self, (SEL)"retain");
}

static void _I_StackBlockClass_dealloc(struct StackBlockClass * self, SEL _cmd)
{
    __Block_release(self);
}

static void _I_StackBlockClass_release(struct StackBlockClass * self, SEL _cmd)
{
    _I_StackBlockClass_dealloc(self, (SEL)"dealloc");
}

static NSUInteger _I_StackBlockClass_retainCount(struct StackBlockClass * self, SEL _cmd)
{
    return self->reserved;
}

static NSString * _I_StackBlockClass_description(struct StackBlockClass * self, SEL _cmd)
{
    return [NSString stringWithFormat:@"Stack Block object=%p address=%p", self, self->invoke];
}

// @end

#if 0 // GlobalBlockClass: Not much to do in here...
{
#endif

#ifndef _REWRITER_typedef_GlobalBlockClass
#define _REWRITER_typedef_GlobalBlockClass
typedef struct objc_object GlobalBlockClass;
#endif

struct GlobalBlockClass {
    Class isa; // initialized to &_NSConcreteStackBlock or &_NSConcreteGlobalBlock
    int flags;
    int reserved; 
    void (*invoke)(void *, ...);
    struct {
        unsigned long int reserved;	// NULL
    	unsigned long int size;  // sizeof(struct Block_literal_1)
    } *descriptor;
    // no imported variables
};

// @end

// @implementation GlobalBlockClass

static id _I_GlobalBlockClass_copy(struct GlobalBlockClass * self, SEL _cmd)
{
    return (id)self;
}

static id _I_GlobalBlockClass_retain(struct GlobalBlockClass * self, SEL _cmd)
{
    return (id)self;
}

static void _I_GlobalBlockClass_release(struct GlobalBlockClass * self, SEL _cmd)
{
}

static void _I_GlobalBlockClass_dealloc(struct GlobalBlockClass * self, SEL _cmd)
{
}

static NSUInteger _I_GlobalBlockClass_retainCount(struct GlobalBlockClass * self, SEL _cmd)
{
    return UINT_MAX;
}

static NSString * _I_GlobalBlockClass_description(struct GlobalBlockClass * self, SEL _cmd)
{
    return [NSString stringWithFormat:@"Global Block object=%p address=%p", self, self->invoke];
}

// @end
#if 0
}
#endif

#define __OFFSETOFIVAR__(TYPE, MEMBER) ((int) &((TYPE *)0)->MEMBER)

struct psy_objc_method {
	SEL _cmd;
	char *method_types;
	void *_imp;
};

static struct {
	struct _objc_method_list *next_method;
	int method_count;
	struct psy_objc_method method_list[6];
} _OBJC_INSTANCE_METHODS_StackBlockClass __attribute__ ((used, section ("__OBJC, __inst_meth")))= {
0, 6
,{{(SEL)"copy", "@8@0:4", (void *)_I_StackBlockClass_copy}
,{(SEL)"retain", "@8@0:4", (void *)_I_StackBlockClass_retain}
,{(SEL)"release", "Vv8@0:4", (void *)_I_StackBlockClass_release}
,{(SEL)"dealloc", "v8@0:4", (void *)_I_StackBlockClass_dealloc}
,{(SEL)"retainCount", "I8@0:4", (void *)_I_StackBlockClass_retainCount}
,{(SEL)"description", "@8@0:4", (void *)_I_StackBlockClass_description}
}
};

struct psy_objc_class {
	struct psy_objc_class *isa;
	const char *super_class_name;
	char *name;
	long version;
	long info;
	long instance_size;
	struct _objc_ivar_list *ivars;
	struct _objc_method_list *methods;
	struct objc_cache *cache;
	struct _objc_protocol_list *protocols;
	const char *ivar_layout;
	struct _objc_class_ext  *ext;
};

static struct psy_objc_class _OBJC_METACLASS_StackBlockClass __attribute__ ((used, section ("__OBJC, __meta_class")))= {
(struct psy_objc_class *)"NSObject", "NSObject", "StackBlockClass", 0,2, sizeof(struct psy_objc_class), 0, 0
,0,0,0,0
};
#define _OBJC_CLASS_StackBlockClass _NSConcreteStackBlock
struct psy_objc_class _NSConcreteStackBlock __attribute__ ((used, section ("__OBJC, __class")))= {
&_OBJC_METACLASS_StackBlockClass, "NSObject", "StackBlockClass", 0,1,sizeof(struct StackBlockClass),0, (struct _objc_method_list *)&_OBJC_INSTANCE_METHODS_StackBlockClass, 0
,0,0,0
};

static struct {
	struct _objc_method_list *next_method;
	int method_count;
	struct psy_objc_method method_list[6];
} _OBJC_INSTANCE_METHODS_GlobalBlockClass __attribute__ ((used, section ("__OBJC, __inst_meth")))= {
0, 6
,{{(SEL)"copy", "@8@0:4", (void *)_I_GlobalBlockClass_copy}
,{(SEL)"retain", "@8@0:4", (void *)_I_GlobalBlockClass_retain}
,{(SEL)"release", "Vv8@0:4", (void *)_I_GlobalBlockClass_release}
,{(SEL)"dealloc", "v8@0:4", (void *)_I_GlobalBlockClass_dealloc}
,{(SEL)"retainCount", "I8@0:4", (void *)_I_GlobalBlockClass_retainCount}
,{(SEL)"description", "@8@0:4", (void *)_I_GlobalBlockClass_description}
}
};

static struct psy_objc_class _OBJC_METACLASS_GlobalBlockClass __attribute__ ((used, section ("__OBJC, __meta_class")))= {
(struct psy_objc_class *)"NSObject", "NSObject", "GlobalBlockClass", 0,2, sizeof(struct psy_objc_class), 0, 0
,0,0,0,0
};
#define _OBJC_CLASS_GlobalBlockClass _NSConcreteGlobalBlock
struct psy_objc_class _NSConcreteGlobalBlock __attribute__ ((used, section ("__OBJC, __class")))= {
&_OBJC_METACLASS_GlobalBlockClass, "NSObject", "GlobalBlockClass", 0,1,sizeof(struct GlobalBlockClass),0, (struct _objc_method_list *)&_OBJC_INSTANCE_METHODS_GlobalBlockClass, 0
,0,0,0
};

struct psy_objc_symtab {
	long sel_ref_cnt;
	SEL *refs;
	short cls_def_cnt;
	short cat_def_cnt;
	void *defs[2];
};

static struct psy_objc_symtab PSY_OBJC_SYMBOLS __attribute__((used, section ("__OBJC, __symbols")))= {
0, 0, 2, 0
,&_OBJC_CLASS_StackBlockClass
,&_OBJC_CLASS_GlobalBlockClass
};


struct psy_objc_module {
	long version;
	long size;
	const char *name;
	struct psy_objc_symtab *symtab;
};

static struct psy_objc_module PSY_OBJC_MODULES __attribute__ ((used, section ("__OBJC, __module_info")))= {
7, sizeof(struct psy_objc_module), "", &PSY_OBJC_SYMBOLS
};

// Copy a block to the heap if it's still on the stack or increments its retain count.
// The block is considered on the stack if self->descriptor->reserved == 0.
void *__Block_copy(void *src)
{
    struct StackBlockClass *self = src;
    struct StackBlockClass *ret;
    if(self->isa == &_NSConcreteGlobalBlock)
    {
        ret = self;
    }
    else if(self->flags & BLOCK_HAS_DESCRIPTOR)
    {
        if(self->descriptor->reserved == 0)
        {
            ret = malloc(self->descriptor->size);
            memcpy(ret, self, self->descriptor->size);
            ret->reserved++;
            if(self->flags & BLOCK_HAS_COPY_DISPOSE)
                self->descriptor->copy_helper(ret, self);
        }
        else
        {
            if(self->reserved > 0) self->descriptor->reserved++;
            ret = self;
        }
    }
    return ret;
}

// Release a block and frees the memory when the retain count hits zero.
void __Block_release(void *src)
{
    struct StackBlockClass *self = src;
    
    if(self->isa == &_NSConcreteStackBlock)
    {
        self->reserved--;
        if(self->reserved == 0)
        {
            if(self->flags & BLOCK_HAS_COPY_DISPOSE)
                self->descriptor->dispose_helper(self);
            free(self);
        }
    }
}
