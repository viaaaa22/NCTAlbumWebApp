<%@ page contentType="text/html" pageEncoding="UTF-8"%>
<%@ page import="java.util.List" %>
<%@ page import="Model.TransactionBean" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Transaction History</title>
    <link rel="shortcut icon" href="img/logonct.png" type="image/x-icon">
    <link href="https://stackpath.bootstrapcdn.com/bootstrap/4.5.2/css/bootstrap.min.css" rel="stylesheet">
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Zen+Maru+Gothic&display=swap');
        body, html {
            font-family: 'Zen Maru Gothic';
            margin: 0;
            padding: 0;
            background-color: #FFFFEF;
        }
        .table-custom {
            border: 1px solid #dee2e6;
            border-collapse: collapse;
        }
        .table-custom th, .table-custom td {
            border: 1px solid #dee2e6;
        }
        .album-table {
            margin-bottom: 0;
        }
        .album-table th, .album-table td {
            border: none;
            background-color: #f8f9fa;
        }
        .btn-pesanan-diterima {
            margin-top: 10px;
        }
        .countdown-timer {
            font-size: 16px;
            font-weight: bold;
            color: red;
        }
        .modal-backdrop {
            z-index: 1040 !important;
        }
        .modal-dialog {
            margin-top: 15%;
        }
    </style>
    <script src="https://code.jquery.com/jquery-3.5.1.min.js"></script>
    <script>
        function openPaymentModal(orderId, ProofPayment, totalPrice) {
            document.getElementById('paymentOrderId').value = orderId;
            document.getElementById('paymentProofPayment').innerText = ProofPayment;
            document.getElementById('paymentTotalPrice').innerText = 'Total Price: ' + totalPrice;
            $('#paymentModal').modal('show');
        }

        function closePaymentModal() {
            $('#paymentModal').modal('hide');
        }

        async function submitPaymentForm(event) {
            event.preventDefault();
            const form = event.target;
            const formData = new FormData(form);

            const response = await fetch('PaymentServlet', {
                method: 'POST',
                body: formData
            });

            const result = await response.json();
            const { status, message, orderId } = result;

            if (status === 'success') {
                $('#paymentModal').modal('hide');
                $('#successModal').modal('show');
                $('#countdown-' + orderId).hide();
                $('#payButton-' + orderId).remove();
                $('#status-' + orderId).text('PEMBAYARAN BERHASIL');
                $('#expiry-' + orderId).text('SUCCESS');
            } else {
                alert(message);
            }
        }

        function updateOrderStatus(orderId, newStatus) {
            $.ajax({
                type: 'POST',
                url: 'UpdateOrderStatusServlet',
                data: {
                    orderId: orderId,
                    status: newStatus
                },
                success: function(response) {
                    const [status, message] = response.split(':');
                    if (status === 'success') {
                        if (newStatus === 'gagal') {
                            $('#failureModal').modal('show');
                            $('#payButton-' + orderId).remove();
                            $('#expiry-' + orderId).text('EXPIRED');
                        }
                    } else {
                        alert(message);
                    }
                },
                error: function() {
                    alert('An error occurred while updating the order status.');
                }
            });
        }

        function startCountdown(expiryTime, orderId, currentStatus) {
            if (currentStatus === 'SUCCESS' || currentStatus === 'sudah_bayar' || currentStatus ==='diterima') {
                $('#expiry-' + orderId).text('SUCCESS');
                return;
            } else if (currentStatus === 'diantar'){
                 $('#expiry-' + orderId).text('Pesanan Diantar');
                return;
            } else if (currentStatus ==='gagal'){
                $('#expiry-' + orderId).text('Pesanan Gagal');
                return;
            }

            const countdownElement = document.getElementById('countdown-' + orderId);
            const countDownDate = new Date(expiryTime).getTime();

            const countdownInterval = setInterval(function() {
                const now = new Date().getTime();
                const distance = countDownDate - now;

                const minutes = Math.floor((distance % (1000 * 60 * 60)) / (1000 * 60));
                const seconds = Math.floor((distance % (1000 * 60)) / 1000);

                countdownElement.innerHTML = minutes + "m " + seconds + "s ";

                if (distance < 0) {
                    clearInterval(countdownInterval);
                    countdownElement.innerHTML = "EXPIRED";
                    updateOrderStatus(orderId, 'gagal');
                }
            }, 1000);
        }
    </script>
</head>
<body>
    <div class="container mt-5">
        <h2>Transaction</h2>
        <table class="table table-custom">
            <thead>
                <tr>
                    <th rowspan="2">Order ID</th>
                    <th colspan="2">Album and Quantity</th>
                    <th rowspan="2">Total Price</th>
                    <th rowspan="2">Order Date</th>
                    <th rowspan="2">Payment Method</th>
                    <th rowspan="2">Status</th>
                    <th rowspan="2">Expiry Time</th>
                </tr>
                <tr>
                    <th>album Name</th>
                    <th>Quantity</th>
                </tr>
            </thead>
            <tbody>
                <% 
                    List<TransactionBean> transactionList = (List<TransactionBean>) request.getAttribute("transactionList");
                    if (transactionList != null && !transactionList.isEmpty()) {
                        for (TransactionBean transaction : transactionList) {
                            String[] albumNames = transaction.getAlbumNames().split(", ");
                            String[] quantities = transaction.getQuantities().split(", ");
                %>
                <tr>
                    <td rowspan="<%= albumNames.length %>"><%= transaction.getOrderId() %></td>
                    <td><%= albumNames[0] %></td>
                    <td><%= quantities[0] %></td>
                    <td rowspan="<%= albumNames.length %>"><%= transaction.getTotalPrice() %></td>
                    <td rowspan="<%= albumNames.length %>"><%= transaction.getOrderDate() %></td>
                    <td rowspan="<%= albumNames.length %>"><%= transaction.getPaymentMethod() %></td>
                    <td id="status-<%= transaction.getOrderId() %>" rowspan="<%= albumNames.length %>">
                        <% if ("belum_bayar".equals(transaction.getStatus())) { %>
                            <button id="payButton-<%= transaction.getOrderId() %>" class="btn btn-primary" onclick="openPaymentModal('<%= transaction.getOrderId() %>', '<%= transaction.getPaymentCode() %>', '<%= transaction.getTotalPrice() %>')">Pay</button>
                        <% } else if ("diantar".equals(transaction.getStatus())) { %>
                            <div>
                                <%= transaction.getStatus().replace("_", " ") %>
                                <button type="button" class="btn btn-success btn-pesanan-diterima" onclick="updateOrderStatus('<%= transaction.getOrderId() %>', 'diterima')">Order received</button>
                            </div>
                        <% } else { %>
                            <%= transaction.getStatus().replace("_", " ") %>
                        <% } %>
                    </td>
                    <td id="expiry-<%= transaction.getOrderId() %>" rowspan="<%= albumNames.length %>">
                        <div class="countdown-timer" id="countdown-<%= transaction.getOrderId() %>"></div>
                        <script>
                            startCountdown('<%= transaction.getExpiryTime() %>', <%= transaction.getOrderId() %>, '<%= transaction.getStatus() %>');
                        </script>
                    </td>
                </tr>
                <% for (int i = 1; i < albumNames.length; i++) { %>
                <tr>
                    <td><%= albumNames[i] %></td>
                    <td><%= quantities[i] %></td>
                </tr>
                <% } %>
                <%
                        }
                    } else {
                %>
                <tr>
                    <td colspan="8">No transactions found</td>
                </tr>
                <%
                    }
                %>
            </tbody>
        </table>
        <a href="index.jsp" class="btn btn-primary">Back to Home</a>
    </div>

    <!-- Payment Modal -->
    <div id="paymentModal" class="modal fade" tabindex="-1" role="dialog">
        <div class="modal-dialog" role="document">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title">Payment</h5>
                    <button type="button" class="close" onclick="closePaymentModal()" aria-label="Close">
                        <span aria-hidden="true">&times;</span>
                    </button>
                </div>
                <div class="modal-body">
                    <form onsubmit="submitPaymentForm(event)" method="post" enctype="multipart/form-data">
                        <input type="hidden" id="paymentOrderId" name="orderId">
                        <p>Proof Payment: <span id="paymentProofPayment"></span></p>
                        <p id="paymentTotalPrice"></p>
                        <div class="form-group">
                            <label for="paymentProof">Upload Bukti Pembayaran</label>
                            <input type="file" class="form-control" id="paymentProof" name="paymentProof" required>
                        </div>
                        <button type="submit" class="btn btn-primary">Submit</button>
                    </form>
                </div>
            </div>
        </div>
    </div>

    <!-- Success Modal -->
    <div id="successModal" class="modal fade" tabindex="-1" role="dialog">
        <div class="modal-dialog" role="document">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title">Pembayaran Berhasil</h5>
                    <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                        <span aria-hidden="true">&times;</span>
                    </button>
                </div>
                <div class="modal-body">
                    <p>Pembayaran Anda telah berhasil. Terima kasih!</p>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-dismiss="modal" onclick="handleSuccessModalClose()">Tutup</button>
                </div>
            </div>
        </div>
    </div>

    <!-- Failure Modal -->
    <div id="failureModal" class="modal fade" tabindex="-1" role="dialog">
        <div class="modal-dialog" role="document">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title">Pembayaran Gagal</h5>
                    <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                        <span aria-hidden="true">&times;</span>
                    </button>
                </div>
                <div class="modal-body">
                    <p>Waktu untuk melakukan pembayaran telah habis. Silakan melakukan pemesanan ulang.</p>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-dismiss="modal">Tutup</button>
                </div>
            </div>
        </div>
    </div>

    <script src="https://code.jquery.com/jquery-3.5.1.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/@popperjs/core@2.9.3/dist/umd/popper.min.js"></script>
    <script src="https://stackpath.bootstrapcdn.com/bootstrap/4.5.2/js/bootstrap.min.js"></script>
    <script>
        function handleSuccessModalClose() {
            $('#successModal').modal('hide');
        }
    </script>
</body>
</html>
