/*
 * Blocks Runtime
 */

extern struct psy_objc_class _NSConcreteGlobalBlock;
extern struct psy_objc_class _NSConcreteStackBlock;
extern void _Block_object_assign(void *, void *, const int);
extern void _Block_object_dispose(void *, const int);
extern void *__Block_copy(void *);
extern void __Block_release(void *);