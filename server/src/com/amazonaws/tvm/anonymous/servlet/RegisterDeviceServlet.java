/*
 * Copyright 2010-2013 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License").
 * You may not use this file except in compliance with the License.
 * A copy of the License is located at
 *
 *  http://aws.amazon.com/apache2.0
 *
 * or in the "license" file accompanying this file. This file is distributed
 * on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
 * express or implied. See the License for the specific language governing
 * permissions and limitations under the License.
 */

package com.amazonaws.tvm.anonymous.servlet;

import java.io.IOException;
import java.util.logging.Level;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.amazonaws.tvm.Utilities;

import com.amazonaws.tvm.anonymous.exception.DataAccessException;
import com.amazonaws.tvm.anonymous.exception.MissingParameterException;

public class RegisterDeviceServlet extends RootServlet {
    private static final long serialVersionUID = 1L;

    @Override
    public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException, ServletException {
        log.info("entering register device request");

        try {
            // Validate parameters
            log.info("Validate parameters");

            String uid = getRequiredParameter(request, "uid");
            String key = getRequiredParameter(request, "key");

            if (!Utilities.isValidUID(uid) || !Utilities.isValidKey(key)) {
                log.warning(String.format("Invalid input uid [ %s ], key [%s]", uid, key));
                sendErrorResponse(HttpServletResponse.SC_BAD_REQUEST, response);
            }

            if (!tvm.registerDevice(uid, key)) {
                log.warning("Device is already registered. Setting Http status code " + HttpServletResponse.SC_CONFLICT);
                sendErrorResponse(HttpServletResponse.SC_CONFLICT, response);
                return;
            }

            log.info("Device successfully registered. Setting Http status code " + HttpServletResponse.SC_OK);
            sendOKResponse(response, null);
        } catch (MissingParameterException e) {
            log.warning("Missing parameter: " + e.getMessage() + ". Setting Http status code "
                    + HttpServletResponse.SC_BAD_REQUEST);
            sendErrorResponse(HttpServletResponse.SC_BAD_REQUEST, response);
        } catch (DataAccessException e) {
            log.log(Level.SEVERE, "Failed to access data", e);
            sendErrorResponse(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, response);
        }

        log.info("leaving processRequest");
    }

}
