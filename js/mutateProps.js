/**
 * @fileOverview The util returns a hard copy of the object
 * with mutated by user callback props. 
 * Check the `withEscapedStrings` func to see how it could be used.
 */
export const mutateProps = (obj, fn) => {	
  if (typeof obj !== 'object' || obj === null) {
    return fn(obj)
  }

  if (Array.isArray(obj)) {
    return obj.map(val => mutateProps(val, fn))
  }

  return Object.fromEntries(
    Object.entries(obj).map(([key, value]) => [key, mutateProps(value, fn)])
  )
}

export const withEscapedStrings = obj =>
  mutateProps(obj, value =>
    typeof value === 'string' ? escapeString(value) : value
  )

