/**
 * Error Handling Middleware
 * {{PROJECT_NAME}}
 * 
 * Centralized error handling for the application.
 */

/**
 * Express error handling middleware
 * Must have 4 parameters to be recognized as error middleware
 */
const errorMiddleware = (err, req, res, next) => {
  // Log the error
  console.error(`[${req.id}] Error:`, err);

  // Determine status code
  const statusCode = err.statusCode || err.status || 500;

  // Prepare error response
  const errorResponse = {
    error: err.name || 'InternalServerError',
    message: err.message || 'An unexpected error occurred',
    requestId: req.id
  };

  // Include stack trace in development
  if (process.env.NODE_ENV === 'development') {
    errorResponse.stack = err.stack;
  }

  // Include validation errors if present
  if (err.errors) {
    errorResponse.errors = err.errors;
  }

  res.status(statusCode).json(errorResponse);
};

module.exports = errorMiddleware;
