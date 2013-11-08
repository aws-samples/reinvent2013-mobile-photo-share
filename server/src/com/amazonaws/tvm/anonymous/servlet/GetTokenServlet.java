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

import com.amazonaws.tvm.anonymous.exception.DataAccessException;
import com.amazonaws.tvm.anonymous.exception.MissingParameterException;
import com.amazonaws.tvm.anonymous.exception.UnauthorizedException;

/**
 * Servlet implementation class GetTokenServlet
 */
public class GetTokenServlet extends RootServlet {
    private static final long serialVersionUID = 1L;

    @Override
    public void doGet(HttpServletRequest request, HttpServletResponse response) throws IOException, ServletException {
        log.info("entering get token request");

        try {
            log.info("Validate parameters");
            String uid = getRequiredParameter(request, "uid");
            String signature = getRequiredParameter(request, "signature");
            String timestamp = getRequiredParameter(request, "timestamp");

            log.info(String.format("Get token with uid [%s] timestamp [%s]", uid, timestamp));

            log.info("validate token request");
            tvm.validateTokenRequest(uid, signature, timestamp);

            log.info("get token for device: " + uid);
            String data = tvm.getToken(uid);
            sendOKResponse(response, data);
        } catch (MissingParameterException e) {
            log.warning("Missing parameter: " + e.getMessage() + ". Setting Http status code "
                    + HttpServletResponse.SC_BAD_REQUEST);
            sendErrorResponse(HttpServletResponse.SC_BAD_REQUEST, response);
        } catch (DataAccessException e) {
            log.log(Level.SEVERE, "Failed to access data", e);
            sendErrorResponse(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, response);
        } catch (UnauthorizedException e) {
            log.warning("Unauthorized access due to: " + e.getMessage());
            sendErrorResponse(HttpServletResponse.SC_UNAUTHORIZED, response);
        }

        log.info("leaving get token request");
    }
}
