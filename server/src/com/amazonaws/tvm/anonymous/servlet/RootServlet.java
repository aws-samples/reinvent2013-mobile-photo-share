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
import java.util.logging.Logger;

import javax.servlet.ServletException;
import javax.servlet.ServletOutputStream;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.amazonaws.tvm.Constants;

import com.amazonaws.tvm.anonymous.AnonymousTokenVendingMachine;
import com.amazonaws.tvm.TokenVendingMachineLogger;
import com.amazonaws.tvm.anonymous.exception.MissingParameterException;

/**
 * An abstract class for TVM servlets.
 */
public abstract class RootServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    protected static final Logger log = TokenVendingMachineLogger.getLogger();

    protected AnonymousTokenVendingMachine tvm;

    @Override
    public void init() throws ServletException {
        super.init();
        tvm = new AnonymousTokenVendingMachine();
    }

    @Override
    public void doGet(HttpServletRequest request, HttpServletResponse response) throws IOException, ServletException {
        doPost(request, response);
    }

    protected String getServletParameter(HttpServlet servlet, String parameterName) {
        String parameterValue = servlet.getInitParameter(parameterName);
        if (parameterValue == null) {
            parameterValue = servlet.getServletContext().getInitParameter(parameterName);
        }

        return parameterValue;
    }

    protected String getRequiredParameter(HttpServletRequest request, String parameterName)
            throws MissingParameterException {
        String value = request.getParameter(parameterName);
        if (value == null) {
            throw new MissingParameterException(parameterName);
        }

        value = value.trim();
        if (value.length() == 0) {
            throw new MissingParameterException(parameterName);
        }
        else {
            return value;
        }
    }

    public void sendErrorResponse(int httpResponseCode, HttpServletResponse response) throws IOException {
        response.setStatus(httpResponseCode);
        response.setContentType("text/plain; charset=UTF-8");
        response.setDateHeader("Expires", System.currentTimeMillis());

        ServletOutputStream out = response.getOutputStream();
        out.println(Constants.getMsg(httpResponseCode));
    }

    public void sendOKResponse(HttpServletResponse response, String data) throws IOException {
        response.setStatus(HttpServletResponse.SC_OK);
        response.setContentType("text/plain; charset=UTF-8");
        response.setDateHeader("Expires", System.currentTimeMillis());

        if (null != data) {
            ServletOutputStream out = response.getOutputStream();
            out.println(data);
        }
    }

}
